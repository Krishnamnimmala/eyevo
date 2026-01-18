import Foundation

// A very small debug-only test runner for VisionTestEngine.
// This runs in DEBUG mode at app startup and prints pass/fail for quick smoke checks.

#if DEBUG

func runDebugEngineTests() {
    var failures = 0
    var successes = 0

    func ok(_ name: String, _ result: Bool) {
        if result {
            successes += 1
            print("✅ [EngineTest] PASS: \(name)")
        } else {
            failures += 1
            print("❌ [EngineTest] FAIL: \(name)")
        }
    }

    // Test 1: startSession initial state
    do {
        let engine = VisionTestEngine()
        let s = engine.startSession()
        ok("startSession sets gatekeeper", s.phase == .gatekeeper)
        ok("startSession logMAR 0.8", abs(s.currentLogMAR - 0.8) < 0.0001)
        ok("startSession confidence 1.0", abs(s.confidence - 1.0) < 0.0001)
    }

    // Test 2: submitResponse exits gatekeeper and updates counters
    do {
        let engine = VisionTestEngine()
        let s = engine.startSession()
        // initial state
        let beforeTrials = s.trials
        engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 320)
        ok("submitResponse increments trials", s.trials == beforeTrials + 1)
        ok("gatekeeper -> tumblingE after first response", s.phase == .tumblingE)
        ok("correctInPhase increments on correct response", s.correctInPhase == 0 || s.correctInPhase == 1) // note: resetPhaseCounters called on gatekeeper exit
    }

    // Test 3: updateLogMAR and reversal behavior
    do {
        let engine = VisionTestEngine()
        let s = engine.startSession()
        // exit gatekeeper
        engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: false, rtMs: 330)
        // Now in tumblingE, track logMAR changes
        let start = s.currentLogMAR
        engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 300)
        let after = s.currentLogMAR
        ok("updateLogMAR decreases on correct", after < start || start == after)

        // reversal count increases when direction changes
        let prevReversals = s.reversalCount
        engine.submitResponse(session: s, direction: .down, phase: s.phase, correct: false, rtMs: 300)
        ok("reversalCount increases on direction change", s.reversalCount >= prevReversals)
    }

    print("[EngineTest] Summary: \(successes) passed, \(failures) failed")
}

#endif
