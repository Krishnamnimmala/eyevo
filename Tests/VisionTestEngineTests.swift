import XCTest
@testable import EYEVO

final class VisionTestEngineTests: XCTestCase {

    func testStartSession_initialState() {
        let engine = VisionTestEngine()
        let s = engine.startSession()
        XCTAssertEqual(s.phase, .gatekeeper)
        XCTAssertEqual(s.currentLogMAR, 0.8, accuracy: 1e-6)
        XCTAssertEqual(s.confidence, 1.0, accuracy: 1e-6)
    }

    func testSubmitResponse_gatekeeperExitAndCounters() {
        let engine = VisionTestEngine()
        let s = engine.startSession()
        let beforeTrials = s.trials
        engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 320)
        XCTAssertEqual(s.trials, beforeTrials + 1)
        XCTAssertEqual(s.phase, .tumblingE)
    }

    func testUpdateLogMAR_andReversalCount() {
        let engine = VisionTestEngine()
        let s = engine.startSession()
        // exit gatekeeper
        engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: false, rtMs: 330)
        let start = s.currentLogMAR
        engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 300)
        let after = s.currentLogMAR
        XCTAssertLessThanOrEqual(after, start)

        let prevReversals = s.reversalCount
        engine.submitResponse(session: s, direction: .down, phase: s.phase, correct: false, rtMs: 300)
        XCTAssertGreaterThanOrEqual(s.reversalCount, prevReversals)
    }

    // New test: QuestAlgorithm integration smoke test
    func testQuestAlgorithm_updatesPosteriorAndSize() {
        let quest = QuestAlgorithm()
        let engine = VisionTestEngine(algorithm: quest)
        let s = engine.startSession()

        // perform a sequence of responses and ensure currentLogMAR changes
        let initial = s.currentLogMAR
        for i in 0..<6 {
            let stim = engine.nextStimulus(session: s)
            let correct = (i < 3)
            engine.submitResponse(session: s, direction: stim.expectedAnswer, phase: stim.phase, correct: correct, rtMs: 300)
        }
        XCTAssertNotEqual(s.currentLogMAR, initial)
    }

    // New test: auto-switch policy moves from Staircase to Quest when accuracy is high
    func testAutoSwitch_toQuest() {
        let engine = VisionTestEngine(algorithm: StaircaseAlgorithm())
        let s = engine.startSession()
        // exit gatekeeper first
        engine.submitResponse(session: s, direction: .up, phase: s.phase, correct: true, rtMs: 300)
        // simulate a streak of correct answers to exceed warmup and threshold
        for _ in 0..<6 {
            let stim = engine.nextStimulus(session: s)
            engine.submitResponse(session: s, direction: stim.expectedAnswer, phase: stim.phase, correct: true, rtMs: 300)
        }
        // engine should have switched algorithms to QuestAlgorithm at some point
        XCTAssertTrue(engine.algorithmName.contains("Quest") || engine.algorithmName.contains("QuestAlgorithm"))
    }
}
