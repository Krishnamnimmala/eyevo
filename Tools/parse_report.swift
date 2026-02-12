import Foundation

struct TrialRecord: Decodable {
    let trial: Int
    let phase: String
    let correct: Bool
    let rtMs: Int
    let currentLogMAR: Double
    let reversals: Int
    let confidence: Double
    let diagConfidence: Double
}

// Use a flexible decoder for the `fullResponses` field which contains heterogenous arrays
struct AnyCodable: Decodable {
    enum Value {
        case bool(Bool)
        case int(Int)
        case double(Double)
        case string(String)
        case array([AnyCodable])
        case object([String: AnyCodable])
        case null
    }

    let value: Value

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = .null
            return
        }
        if let b = try? container.decode(Bool.self) {
            self.value = .bool(b); return
        }
        if let i = try? container.decode(Int.self) {
            self.value = .int(i); return
        }
        if let d = try? container.decode(Double.self) {
            self.value = .double(d); return
        }
        if let s = try? container.decode(String.self) {
            self.value = .string(s); return
        }
        if let arr = try? container.decode([AnyCodable].self) {
            self.value = .array(arr); return
        }
        if let obj = try? container.decode([String: AnyCodable].self) {
            self.value = .object(obj); return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
    }
}

struct RunReport: Decodable {
    let step: Double
    let reversalsThreshold: Int
    let trials: [TrialRecord]
    let fullResponses: [[AnyCodable]]?
    let tumblingEResultLogMAR: Double?
    let estimatedLogMAR: Double?
    let confidence: Double?
    let isValid: Bool
    let passed: Bool
}

let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/stairs_report.json"
let url = URL(fileURLWithPath: path)

func shortString(for any: AnyCodable) -> String {
    switch any.value {
    case .bool(let b): return b ? "true" : "false"
    case .int(let i): return String(i)
    case .double(let d): return String(d)
    case .string(let s): return "\"\(s)\""
    case .null: return "null"
    case .array(let a): return "[\(a.map { shortString(for: $0) }.joined(separator: ", "))]"
    case .object(let o): return "{...\(o.count) entries...}"
    }
}

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

if !FileManager.default.fileExists(atPath: path) {
    print("Report file not found at \(path). Run the simulator with --json <path> to create one.")
    exit(1)
}

do {
    let data = try Data(contentsOf: url)
    let report = try decoder.decode(RunReport.self, from: data)

    print("Run summary for: \(path)")
    print(String(format: "step=%.3f, reversalsThreshold=%d", report.step, report.reversalsThreshold))
    print("trials=", report.trials.count)
    if let est = report.estimatedLogMAR {
        print(String(format: "estimatedLogMAR=%.3f", est))
    } else {
        print("estimatedLogMAR=null")
    }
    print(String(format: "confidence=%.3f", report.confidence ?? 0.0))
    print("isValid=\(report.isValid) passed=\(report.passed)")

    print("\nLast 5 trials:")
    for t in report.trials.suffix(5) {
        print(String(format: "#%2d %@ correct=%5@ logMAR=%.3f rev=%d conf=%.3f diag=%.3f",
                     t.trial, t.phase, t.correct ? "true" : "false", t.currentLogMAR, t.reversals, t.confidence, t.diagConfidence))
    }

    if let full = report.fullResponses {
        print("\nFull responses (first 10):")
        for (i, pair) in full.prefix(10).enumerated() {
            let rendered = pair.map { shortString(for: $0) }.joined(separator: ", ")
            print("#\(i+1): [\(rendered)]")
        }
    }

} catch {
    print("Failed to read or parse report at \(path): \(error)")
    exit(1)
}
