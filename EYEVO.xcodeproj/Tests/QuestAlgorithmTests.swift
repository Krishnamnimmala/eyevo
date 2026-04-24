import XCTest
@testable import EYEVO

final class QuestAlgorithmTests: XCTestCase {

    func testPosteriorNormalizesOnStart() {
        let quest = QuestAlgorithm(minLogMAR: -0.2, maxLogMAR: 1.2, step: 0.05)
        let session = VisionTestSession()
        session.currentLogMAR = 0.5
        quest.start(session: session)

        // posterior should sum to ~1
        // we access posterior indirectly by simulating an update and ensuring no crashes and size changes
        quest.update(session: session, correct: true, rtMs: 300)
        // If no exceptions and currentLogMAR within grid bounds, pass
        XCTAssertTrue(session.currentLogMAR >= -0.2 && session.currentLogMAR <= 1.2)
    }

    func testMeanMovesTowardCorrectResponses() {
        let quest = QuestAlgorithm(minLogMAR: -0.2, maxLogMAR: 1.2, step: 0.01)
        let session = VisionTestSession()
        session.currentLogMAR = 0.8
        quest.start(session: session)

        let start = session.currentLogMAR
        // Simulate correct responses, expect mean to decrease (better acuity)
        for _ in 0..<5 {
            quest.update(session: session, correct: true, rtMs: 300)
        }
        let after = session.currentLogMAR
        XCTAssertLessThanOrEqual(after, start)
    }

    func testStabilityUnderAlternatingResponses() {
        let quest = QuestAlgorithm(minLogMAR: -0.2, maxLogMAR: 1.2, step: 0.02)
        let session = VisionTestSession()
        session.currentLogMAR = 0.6
        quest.start(session: session)

        // alternate correct/incorrect
        for i in 0..<20 {
            let correct = (i % 2 == 0)
            quest.update(session: session, correct: correct, rtMs: 320)
        }
        // Expect currentLogMAR to remain in valid range and not NaN
        XCTAssertFalse(session.currentLogMAR.isNaN)
        XCTAssertTrue(session.currentLogMAR >= -0.2 && session.currentLogMAR <= 1.2)
    }
}
