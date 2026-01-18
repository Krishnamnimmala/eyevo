import Foundation

final class VisionTestEngine {

    // The adaptive algorithm strategy (staircase by default)
    private var algorithm: AdaptiveAlgorithm

    // Auto-switch policy parameters
    private let warmupTrials = 4
    private let accuracyThreshold = 0.75
    private let fallbackAccuracyThreshold = 0.35
    private let recentWindow = 6
    // Diagnostic thresholds (posterior entropy -> confidence)
    private let diagnosticThreshold = 0.55
    private let fallbackDiagnosticThreshold = 0.28

    // Hysteresis: minimum trials between automatic switches to avoid flip-flop
    private var lastSwitchTotalTrials: Int = -999
    private let switchCooldownTrials = 3

    init(algorithm: AdaptiveAlgorithm = StaircaseAlgorithm()) {
        self.algorithm = algorithm
    }

    // Expose algorithm type name for debugging/tests
    var algorithmName: String {
        return String(describing: type(of: algorithm))
    }

    // Allow switching algorithm at runtime (keeps session bookkeeping intact)
    func switchAlgorithm(to newAlgorithm: AdaptiveAlgorithm, session: VisionTestSession) {
        let fromName = String(describing: type(of: self.algorithm))
        let toName = String(describing: type(of: newAlgorithm))
        print("Switching algorithm from \(fromName) to \(toName)")
        TelemetryManager.shared.record(event: "algorithm_switch_request", metadata: ["from": fromName, "to": toName])
        self.algorithm = newAlgorithm
        self.algorithm.initializeFromSession(session: session)
        TelemetryManager.shared.record(event: "algorithm_switched", metadata: ["from": fromName, "to": toName])
    }

    // MARK: - Session Lifecycle

    func startSession() -> VisionTestSession {
        let s = VisionTestSession()
        s.phase = .gatekeeper
        s.currentLogMAR = 0.8
        s.confidence = 1.0
        s.trials = 0
        s.trialsInPhase = 0
        s.totalTrials = 0
        // Let algorithm initialize any algorithm-specific state
        algorithm.start(session: s)
        print("startSession: phase=gatekeeper, starting logMAR=0.8, algorithm=\(algorithmName)")

        // Telemetry: record session start (no PII)
        TelemetryManager.shared.record(event: "session_start", metadata: ["algorithm": algorithmName])
        return s
    }

    // MARK: - Stimulus Generation

    func nextStimulus(session: VisionTestSession) -> Stimulus {
        // Use algorithm to decide next size
        let size = algorithm.nextSize(session: session)
        return Stimulus(
            phase: session.phase,
            optotype: .tumblingE,
            symbol: "E",
            expectedAnswer: randomDirection(),
            sizeLogMAR: size
        )
    }

    // MARK: - Response Handling

    func submitResponse(
        session: VisionTestSession,
        direction: ResponseDirection,
        phase: TestPhase,
        correct: Bool,
        rtMs: Int
    ){
        print("submitResponse enter - phase before=\(session.phase), correct=\(correct), alg=\(algorithmName)")

        // Delegate update to algorithm (algorithm is responsible for bookkeeping)
        algorithm.update(session: session, correct: correct, rtMs: rtMs)

        // After update, consider auto-switching algorithms based on recent accuracy/diagnostic
        maybeAutoSwitch(session: session)

        // Quick gatekeeper flow: exit gatekeeper after the first response
        if session.phase == .gatekeeper {
            print("Exiting gatekeeper -> tumblingE")
            session.phase = .tumblingE
            session.resetPhaseCounters()
            session.stepSize = 0.1
            return
        }

        // Normal phase completion checks
        if shouldStopPhase(session: session) {
            finalizePhase(session: session)
            maybeSwitchToSloan(session: session)
        }

        print("submitResponse exit - phase after=\(session.phase), alg=\(algorithmName)")
    }

    // MARK: - Auto-Switch Policy

    private func recentAccuracy(session: VisionTestSession) -> Double {
        let responses = session.responses
        guard !responses.isEmpty else { return 0.0 }
        let window = min(recentWindow, responses.count)
        let last = responses.suffix(window)
        let correct = last.filter { $0.correct }.count
        return Double(correct) / Double(window)
    }

    private func maybeAutoSwitch(session: VisionTestSession) {
        // Only consider switching during running phases
        guard session.phase == .tumblingE || session.phase == .sloan10 else { return }

        let total = session.totalTrials
        // Respect cooldown/hysteresis
        if total - lastSwitchTotalTrials < switchCooldownTrials {
            return
        }

        let acc = recentAccuracy(session: session)
        let diag = algorithm.diagnosticConfidence(session: session)

        // If currently staircase, consider switching to QUEST when warmup satisfied and diagnostic confidence high
        if type(of: algorithm) == StaircaseAlgorithm.self {
            if total >= warmupTrials && (diag >= diagnosticThreshold || acc >= accuracyThreshold) {
                // Switch to QUEST
                let q = QuestAlgorithm()
                TelemetryManager.shared.record(event: "auto_switch_attempt", metadata: ["from": "Staircase", "to": "Quest", "acc": acc, "diag": diag, "total": total])
                switchAlgorithm(to: q, session: session)
                lastSwitchTotalTrials = total
                print("Auto-switched to QUEST (diag=\(String(format: "%.3f", diag)), acc=\(String(format: "%.3f", acc)), total=\(total))")
                TelemetryManager.shared.record(event: "auto_switch", metadata: ["from": "Staircase", "to": "Quest", "acc": acc, "diag": diag, "total": total])
            }
        } else {
            // If currently QUEST, fall back to staircase when diagnostic confidence collapses or accuracy collapses
            if total >= warmupTrials && (diag <= fallbackDiagnosticThreshold || acc <= fallbackAccuracyThreshold) {
                let s = StaircaseAlgorithm()
                TelemetryManager.shared.record(event: "auto_switch_attempt", metadata: ["from": "Quest", "to": "Staircase", "acc": acc, "diag": diag, "total": total])
                switchAlgorithm(to: s, session: session)
                lastSwitchTotalTrials = total
                print("Auto-fallback to Staircase (diag=\(String(format: "%.3f", diag)), acc=\(String(format: "%.3f", acc)), total=\(total))")
                TelemetryManager.shared.record(event: "auto_switch", metadata: ["from": "Quest", "to": "Staircase", "acc": acc, "diag": diag, "total": total])
            }
        }
    }

    // MARK: - Phase Control

    func shouldStopPhase(session: VisionTestSession) -> Bool {
        switch session.phase {
        case .tumblingE:
            return session.trialsInPhase >= 20 || session.reversalCount >= 6
        case .sloan10:
            return session.trialsInPhase >= 12 || session.reversalCount >= 4
        default:
            return false
        }
    }

    func finalizePhase(session: VisionTestSession) {
        if session.phase == .tumblingE {
            if session.correctInPhase >= 10 && session.confidence >= 0.6 {
                session.sloanEligible = true
                session.tumblingEResultLogMAR = session.currentLogMAR
            }
        }

        if session.phase == .sloan10 {
            session.sloanResultLogMAR = session.currentLogMAR
        }
    }

    func maybeSwitchToSloan(session: VisionTestSession) {
        if session.phase == .tumblingE && session.sloanEligible {
            session.phase = .sloan10
            session.resetPhaseCounters()
            session.stepSize = 0.05
            print("Switching to sloan10")
        } else {
            session.complete()
            print("Session complete")
        }
    }

    // MARK: - Finalization

    func finalizeSession(session: VisionTestSession) -> TestOutcome {
        let valid = session.totalTrials >= 6
        let finalLogMAR = session.sloanResultLogMAR ?? session.tumblingEResultLogMAR
        let passed = valid && (finalLogMAR ?? 1.0) <= 0.3

        let outcome = TestOutcome(
            estimatedLogMAR: valid ? finalLogMAR : nil,
            confidence: valid ? session.confidence : nil,
            isValid: valid,
            passed: passed
        )

        // Telemetry: record session outcome summary
        TelemetryManager.shared.record(event: "session_end", metadata: ["isValid": outcome.isValid, "passed": outcome.passed, "estimatedLogMAR": outcome.estimatedLogMAR ?? NSNull()])

        return outcome
    }

    // MARK: - Internal Helpers

    private func randomDirection() -> ResponseDirection {
        ResponseDirection.allCases.randomElement() ?? .up
    }
}
