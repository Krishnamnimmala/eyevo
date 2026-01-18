import Foundation

// Protocol representing an adaptive algorithm (staircase / QUEST)
protocol AdaptiveAlgorithm {
    // Called when a session starts or algorithm is (re)used for a session
    func start(session: VisionTestSession)

    // Update algorithm state after observing a response
    func update(session: VisionTestSession, correct: Bool, rtMs: Int)

    // Optional: request the next stimulus size (logMAR)
    func nextSize(session: VisionTestSession) -> Double

    // Called when algorithm is chosen mid-session; should initialize internal state
    // without clearing session bookkeeping. Default implementation is no-op.
    func initializeFromSession(session: VisionTestSession)

    // Diagnostic confidence in [0,1] where higher means algorithm is confident/stable.
    // Default returns session.confidence as a basic heuristic.
    func diagnosticConfidence(session: VisionTestSession) -> Double
}

extension AdaptiveAlgorithm {
    func initializeFromSession(session: VisionTestSession) {}
    func diagnosticConfidence(session: VisionTestSession) -> Double { return session.confidence }
}

// Simple staircase implementation ported from previous VisionTestEngine logic.
final class StaircaseAlgorithm: AdaptiveAlgorithm {

    func start(session: VisionTestSession) {
        // Ensure session defaults for staircase
        session.stepSize = 0.1
        // do not clear session counters here — startSession already creates a fresh session
        session.reversalCount = 0
        session.lastDirection = 0
        // note: we intentionally do not remove session.responses here
    }

    func initializeFromSession(session: VisionTestSession) {
        // When switching to staircase mid-session, respect current step size and counters
        // but do not clear historical responses.
        // Ensure step size has a reasonable default
        if session.stepSize <= 0 { session.stepSize = 0.1 }
    }

    func update(session: VisionTestSession, correct: Bool, rtMs: Int) {
        // Update counters
        if correct { session.correctInPhase += 1 }
        session.responses.append((correct: correct, rtMs: rtMs))
        session.trials += 1
        session.trialsInPhase += 1
        session.totalTrials += 1

        // Confidence update (same heuristic)
        if !correct { session.confidence -= 0.05 }
        if rtMs < 250 { session.confidence -= 0.03 }
        session.confidence = max(0.0, min(1.0, session.confidence))

        // Staircase logMAR update
        let direction = correct ? -1 : 1
        if direction != session.lastDirection {
            session.reversalCount += 1
        }
        session.lastDirection = direction
        session.currentLogMAR += Double(direction) * session.stepSize
        session.currentLogMAR = max(-0.2, min(1.2, session.currentLogMAR))
    }

    func nextSize(session: VisionTestSession) -> Double {
        return session.currentLogMAR
    }
}
