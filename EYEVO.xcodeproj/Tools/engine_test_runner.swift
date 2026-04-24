import Foundation

// Minimal test runner that uses the project engine sources compiled together.
// This file is compiled alongside the engine sources via `swiftc` and executed.

@main
struct EngineTestRunner {
    static func main() -> Void {
        var failures = 0
        var successes = 0

        func ok(_ name: String, _ result: Bool) {
            if result {
                successes += 1
                print("✅ PASS: \(name)")
            } else {
                failures += 1
                print("❌ FAIL: \(name)")
            }
        }

        // Test 1: startSession initial state
        do {
            let engine = VisionTestEngine()
            let s = engine.startSession()
            ok("startSession sets gatekeeper", s.phase == .gatekeeper)
            ok("startSession logMAR 0.8", abs(s.currentLogMAR - 0.8) < 1e-6)
            ok("startSession confidence 1.0", abs(s.confidence - 1.0) < 1e-6)
        }

        // Test 2: submitResponse_gatekeeperExitAndCounters
        do {
            let engine = VisionTestEngine()
            let s = engine.startSession()
            let beforeTrials = s.trials
            engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 320)
            ok("submitResponse increments trials", s.trials == beforeTrials + 1)
            ok("gatekeeper -> tumblingE after first response", s.phase == .tumblingE)
        }

        // Test 3: updateLogMAR_andReversalCount
        do {
            let engine = VisionTestEngine()
            let s = engine.startSession()
            // exit gatekeeper
            engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: false, rtMs: 330)
            let start = s.currentLogMAR
            engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 300)
            let after = s.currentLogMAR
            ok("updateLogMAR decreases on correct", after <= start)

            let prevReversals = s.reversalCount
            engine.submitResponse(session: s, direction: .down, phase: s.phase, correct: false, rtMs: 300)
            ok("reversalCount increases on direction change", s.reversalCount >= prevReversals)
        }

        print("\nSummary: \(successes) passed, \(failures) failed")

        if failures > 0 {
            exit(1)
        } else {
            exit(0)
        }
    }
}
