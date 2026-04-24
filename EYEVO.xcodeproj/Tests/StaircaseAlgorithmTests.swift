import XCTest
@testable import EYEVO

final class StaircaseAlgorithmTests: XCTestCase {

    func testTwoDownOneUpBehavior() {
        let algo = StaircaseAlgorithm()
        let engine = VisionTestEngine(algorithm: algo)
        let s = engine.startSession()

        // Ensure default step exists
        XCTAssertTrue(s.stepSize > 0)

        // Exit gatekeeper
        let stim1 = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim1.expectedAnswer, phase: stim1.phase, correct: true, rtMs: 200)

        // Two corrects => one DOWN
        let before = s.currentLogMAR
        let stim2 = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim2.expectedAnswer, phase: stim2.phase, correct: true, rtMs: 200)
        let stim3 = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim3.expectedAnswer, phase: stim3.phase, correct: true, rtMs: 200)
        let afterDown = s.currentLogMAR
        XCTAssertLessThan(afterDown, before, "2-down should decrease currentLogMAR")

        // Incorrect => up and reversal increment
        let prevReversals = s.reversalCount
        let stim4 = engine.nextStimulus(session: s)
        engine.submitResponse(session: s, direction: stim4.expectedAnswer, phase: stim4.phase, correct: false, rtMs: 200)
        XCTAssertGreaterThanOrEqual(s.reversalCount, prevReversals + 1)
    }
}
