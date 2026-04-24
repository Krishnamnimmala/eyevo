import Foundation

func ok(_ name: String, _ result: Bool) {
    if result {
        print("✅ PASS: \(name)")
    } else {
        print("❌ FAIL: \(name)")
    }
}

// Engine basic tests
func testStartSession() {
    let engine = VisionTestEngine()
    let s = engine.startSession()
    ok("startSession sets gatekeeper", s.phase == .gatekeeper)
    ok("startSession logMAR 0.8", abs(s.currentLogMAR - 0.8) < 1e-6)
    ok("startSession confidence 1.0", abs(s.confidence - 1.0) < 1e-6)
}

func testGatekeeperExitAndCounters() {
    let engine = VisionTestEngine()
    let s = engine.startSession()
    engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 320)
    ok("submitResponse increments trials", s.totalTrials >= 1)
    ok("gatekeeper -> tumblingE after first response", s.phase == .tumblingE)
}

func testQuestAlgorithmBehavior() {
    let quest = QuestAlgorithm()
    let engine = VisionTestEngine(algorithm: quest)
    let s = engine.startSession()
    let initial = s.currentLogMAR
    for i in 0..<6 {
        let stim = engine.nextStimulus(session: s)
        let correct = i < 3
        engine.submitResponse(session: s, direction: stim.expectedAnswer, phase: stim.phase, correct: correct, rtMs: 300)
    }
    ok("Quest updates currentLogMAR", s.currentLogMAR >= -0.2 && s.currentLogMAR <= 1.2)
    ok("Quest changed size from initial", s.currentLogMAR != initial)
}

func testAutoSwitchBehavior() {
    // Clear telemetry
    TelemetryManager.shared.clear()

    let engine = VisionTestEngine(algorithm: StaircaseAlgorithm())
    let s = engine.startSession()
    // exit gatekeeper
    engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 300)
    // simulate a streak of correct answers
    for _ in 0..<6 {
        let stim = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim.expectedAnswer, phase: stim.phase, correct: true, rtMs: 300)
    }

    // Inspect telemetry for either an explicit auto_switch to Quest or an algorithm_switched to Quest
    let events = TelemetryManager.shared.fetchEvents()
    let switchedToQuest = events.contains { evt in
        if let name = evt["event"] as? String {
            if name == "auto_switch" {
                if let to = evt["to"] as? String { return to.lowercased().contains("quest") }
                return String(describing: evt).lowercased().contains("quest")
            }
            if name == "algorithm_switched" {
                if let to = evt["to"] as? String { return to.lowercased().contains("quest") }
                return String(describing: evt).lowercased().contains("quest")
            }
        }
        // fallback: check whole dict text
        return String(describing: evt).lowercased().contains("quest")
    }

    ok("Auto-switch to Quest when accuracy high", switchedToQuest)
}

@main
struct EngineUnitRunner {
    static func main() {
        print("Running engine unit tests...")

        testStartSession()
        testGatekeeperExitAndCounters()
        testQuestAlgorithmBehavior()
        testAutoSwitchBehavior()

        print("Engine unit tests complete")
    }
}
