import Foundation

// Minimal smoke runner to exercise VisionTestEngine + QuestAlgorithm
// This file is compiled together with the core sources in the project.

func ok(_ name: String, _ cond: Bool) {
    print(cond ? "✅ \(name)" : "❌ \(name)")
}

print("SMOKE RUN — start")
let quest = QuestAlgorithm()
let engine = VisionTestEngine(algorithm: quest)
let s = engine.startSession()
print("start phase=\(s.phase) logMAR=\(s.currentLogMAR) confidence=\(s.confidence)")

for i in 0..<8 {
    let stim = engine.nextStimulus(session: s)
    // simulate correct for all trials
    let correct = true
    engine.submitResponse(session: s, direction: stim.expectedAnswer, phase: stim.phase, correct: correct, rtMs: 300)
    print("trial \(i+1): phase=\(s.phase) trialsInPhase=\(s.trialsInPhase) correctInPhase=\(s.correctInPhase) currentLogMAR=\(String(format: \"%.3f\", s.currentLogMAR)) confidence=\(String(format: \"%.3f\", s.confidence))")
    if s.phase == .completed { break }
}

let outcome = engine.finalizeSession(session: s)
print("FINAL OUTCOME -> estimatedLogMAR=\(String(describing: outcome.estimatedLogMAR)) confidence=\(String(describing: outcome.confidence)) isValid=\(outcome.isValid) passed=\(outcome.passed)")
print("SMOKE RUN — end")
