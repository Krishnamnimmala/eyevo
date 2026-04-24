import Foundation

func ok(_ name: String, _ cond: Bool) {
    print(cond ? "✅ PASS: \(name)" : "❌ FAIL: \(name)")
}

@main
struct StaircaseUnitRunnerCLI {
    static func main() {
        print("Running staircase unit runner (CLI)...")
        let algo = StaircaseAlgorithm()
        let engine = VisionTestEngine(algorithm: algo)
        let s = engine.startSession()

        // Ensure stepSize read from algorithm default
        let step = s.stepSize
        print("stepSize = \(step)")

        // Exit gatekeeper with a correct response
        let stim1 = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim1.expectedAnswer, phase: stim1.phase, correct: true, rtMs: 200)

        // Now simulate two corrects in tumblingE to cause a down step
        let stim2 = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim2.expectedAnswer, phase: stim2.phase, correct: true, rtMs: 200)
        let stim3 = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim3.expectedAnswer, phase: stim3.phase, correct: true, rtMs: 200)

        let afterDown = s.currentLogMAR
        ok("2-down causes decrease by step", afterDown <= 0.8 - step + 1e-9)

        // Now submit an incorrect to force an up step and reversal
        let stim4 = engine.nextStimulus(session: s)
        let prevReversals = s.reversalCount
        engine.submitResponse(session: s, direction: stim4.expectedAnswer, phase: stim4.phase, correct: false, rtMs: 200)
        let afterUp = s.currentLogMAR
        ok("Incorrect causes increase by step", afterUp >= afterDown + step - 1e-9)
        ok("Reversal count incremented on direction change", s.reversalCount >= prevReversals + 1)

        print("Runner complete")
    }
}
