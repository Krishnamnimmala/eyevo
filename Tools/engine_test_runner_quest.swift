import Foundation

// Runner to exercise VisionTestEngine with QuestAlgorithm
func ok(_ name: String, _ result: Bool) {
    if result {
        print("✅ PASS: \(name)")
    } else {
        print("❌ FAIL: \(name)")
    }
}

@main
struct QuestRunner {
    static func main() {
        // Test: engine with QuestAlgorithm starts and updates posterior
        let engine = VisionTestEngine(algorithm: QuestAlgorithm())
        let s = engine.startSession()
        ok("QUEST startSession sets gatekeeper", s.phase == .gatekeeper)
        ok("QUEST startSession logMAR present", abs(s.currentLogMAR - 0.8) < 1e-6)

        // Present a few trials using engine with quest
        for i in 0..<5 {
            let stim = engine.nextStimulus(session: s)
            // Simulate correct for first 3, incorrect for next
            let correct = i < 3
            engine.submitResponse(session: s, direction: stim.expectedAnswer, phase: stim.phase, correct: correct, rtMs: 300)
            print("trial \(i): currentLogMAR=\(String(format: "%.3f", s.currentLogMAR)), confidence=\(String(format: "%.3f", s.confidence))")
        }

        print("QUEST run complete")
    }
}
