
import Foundation

/// Protocol for adaptive vision-testing algorithms (QUEST, Staircase, etc.)
protocol AdaptiveAlgorithm {

    /// Called once when a new session starts
    func start(session: VisionTestSession)

    /// Called after every response
    func update(
        session: VisionTestSession,
        correct: Bool,
        rtMs: Int
    )
}
