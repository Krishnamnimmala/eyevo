import Foundation

struct Config {
    var step: Double?
    var reversals: Int?
    var verbose: Bool = false
    var mode: String = "normal" // or "pass"
    var sequencePath: String?
    var jsonOutput: String?
}

func parseArgs() -> Config {
    var cfg = Config()
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--step":
            if let v = it.next(), let d = Double(v) { cfg.step = d }
        case "--reversals":
            if let v = it.next(), let n = Int(v) { cfg.reversals = n }
        case "--verbose":
            cfg.verbose = true
        case "--mode":
            if let v = it.next() { cfg.mode = v }
        case "--sequence":
            if let v = it.next() { cfg.sequencePath = v }
        case "--json":
            if let v = it.next() { cfg.jsonOutput = v }
        case "-h", "--help":
            print("Usage: staircase_simulator [--step <double>] [--reversals <int>] [--verbose] [--mode normal|pass] [--sequence <path>] [--json <path>]")
            exit(0)
        default:
            print("Unknown arg: \(a)")
            exit(1)
        }
    }
    return cfg
}

struct TrialRecord: Codable {
    let trial: Int
    let phase: String
    let correct: Bool
    let rtMs: Int
    let currentLogMAR: Double
    let reversals: Int
    let confidence: Double
    let diagConfidence: Double
}

struct RunReport: Codable {
    let step: Double
    let reversalsThreshold: Int
    let trials: [TrialRecord]
    let fullResponses: [(Bool, Int)]
    let tumblingEResultLogMAR: Double?
    let estimatedLogMAR: Double?
    let confidence: Double?
    let isValid: Bool
    let passed: Bool
}

@main
struct StaircaseSimulatorCLI {
    static func main() {
        let cfg = parseArgs()

        // Pass env vars through to algorithm/engine by setting ProcessInfo env (statically read by code)
        if let s = cfg.step { setenv("STAIRCASE_STEP", String(s), 1) }
        if let r = cfg.reversals { setenv("STAIRCASE_REVERSALS", String(r), 1) }
        if cfg.verbose { setenv("STAIRCASE_VERBOSE", "1", 1) }

        print("Staircase simulator (CLI) — mode=\(cfg.mode) step=\(cfg.step ?? -1) reversals=\(cfg.reversals ?? -1) verbose=\(cfg.verbose) sequence=\(cfg.sequencePath ?? "<none>") json=\(cfg.jsonOutput ?? "<none>")")

        let algo = StaircaseAlgorithm()
        let engine = VisionTestEngine(algorithm: algo)
        let session = engine.startSession()

        print("SIMULATOR START: algorithm=StaircaseAlgorithm, stepSize=\(session.stepSize), startLogMAR=\(session.currentLogMAR), startConfidence=\(session.confidence)")

        var pattern: [Bool] = []
        pattern.append(true) // gatekeeper response

        if let seqPath = cfg.sequencePath {
            // Read sequence file (comma/space/newline separated: 1,0,true,false)
            if let data = try? String(contentsOfFile: seqPath) {
                let tokens = data
                    .replacingOccurrences(of: "\n", with: ",")
                    .replacingOccurrences(of: "\r", with: ",")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                for t in tokens {
                    if t.isEmpty { continue }
                    let lower = t.lowercased()
                    if lower == "1" || lower == "true" || lower == "t" {
                        pattern.append(true)
                    } else if lower == "0" || lower == "false" || lower == "f" {
                        pattern.append(false)
                    } else {
                        print("Warning: could not parse token '\(t)' as bool, skipping")
                    }
                }
            } else {
                print("Failed to read sequence file at \(seqPath). Falling back to default pattern.")
            }
        } else if cfg.mode == "pass" {
            // produce many corrects to drive down the staircase
            pattern.append(contentsOf: Array(repeating: true, count: 40))
        } else {
            // normal deterministic pattern: mostly correct with some wrongs
            for _ in 0..<6 { pattern.append(contentsOf: [true, true, false]) }
        }

        var trialRecords: [TrialRecord] = []

        for (i, correct) in pattern.enumerated() {
            let stim = engine.nextStimulus(session: session)
            engine.submitResponse(session: session, direction: stim.expectedAnswer, phase: stim.phase, correct: correct, rtMs: 300)

            let diag = algo.diagnosticConfidence(session: session)
            let rec = TrialRecord(
                trial: i + 1,
                phase: String(describing: session.phase),
                correct: correct,
                rtMs: 300,
                currentLogMAR: session.currentLogMAR,
                reversals: session.reversalCount,
                confidence: session.confidence,
                diagConfidence: diag
            )
            trialRecords.append(rec)

            print("Trial \(i+1) | phase=\(rec.phase) | correct=\(rec.correct) | currentLogMAR=\(String(format: \"%.3f\", rec.currentLogMAR)) | reversals=\(rec.reversals) | confidence=\(String(format: \"%.3f\", rec.confidence)) | diagConfidence=\(String(format: \"%.3f\", rec.diagConfidence)) | trialsInPhase=\(session.trialsInPhase)")

            if session.phase == .completed { break }
            if session.totalTrials > 200 { break }
        }

        print("\nFULL RESPONSES (correct, rtMs): \(session.responses)")
        engine.finalizePhase(session: session)
        print("tumblingEResultLogMAR (post-finalizePhase) = \(String(describing: session.tumblingEResultLogMAR))")
        let outcome = engine.finalizeSession(session: session)
        print("SIMULATOR END: estimatedLogMAR=\(String(describing: outcome.estimatedLogMAR)), confidence=\(String(describing: outcome.confidence)), isValid=\(outcome.isValid), passed=\(outcome.passed)")

        if let jsonPath = cfg.jsonOutput {
            let report = RunReport(
                step: session.stepSize,
                reversalsThreshold: VisionTestEngine.defaultTumblingEReversalThreshold,
                trials: trialRecords,
                fullResponses: session.responses.map { ($0.correct, $0.rtMs) },
                tumblingEResultLogMAR: session.tumblingEResultLogMAR,
                estimatedLogMAR: outcome.estimatedLogMAR,
                confidence: outcome.confidence,
                isValid: outcome.isValid,
                passed: outcome.passed
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(report) {
                do {
                    try data.write(to: URL(fileURLWithPath: jsonPath))
                    print("Wrote JSON report to \(jsonPath)")
                } catch {
                    print("Failed to write JSON to \(jsonPath): \(error)")
                }
            } else {
                print("Failed to encode JSON report")
            }
        }
    }
}
