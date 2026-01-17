import Foundation

// MARK: - Session

// MARK: - Engine

final class VisionTestEngine {

    // Sloan 10 letter set (STANDARD)
    private let sloanLetters = ["C","D","H","K","N","O","R","S","V","Z"]

    // MARK: - Public API

    func startSession() -> VisionTestSession {
        return VisionTestSession()
    }

    func nextStimulus(session: VisionTestSession) -> Stimulus?
 {

        session.trials += 1

        switch session.phase {

        case .gatekeeper:
            return Stimulus(
                phase: .gatekeeper,
                optotype: .tumblingE,
                symbol: "E",
                expectedAnswer: randomDirection(),
                sizeLogMAR: 1.0
            )

        case .tumblingE:
            return Stimulus(
                phase: .tumblingE,
                optotype: .tumblingE,
                symbol: "E",
                expectedAnswer: randomDirection(),
                sizeLogMAR: session.currentLogMAR
            )

        case .sloan10:
            let letter = sloanLetters.randomElement()!
            return Stimulus(
                phase: .sloan10,
                optotype: .sloanLetter,
                symbol: letter,
                expectedAnswer: letter,
                sizeLogMAR: session.currentLogMAR
            )

        case .completed:
            return nil

        }
    }

    func submitResponse(
        session: VisionTestSession,
        direction: Direction,
        phase: TestPhase,
        correct: Bool,
        rtMs: Int
    ) {
        
        
        session.responses.append((correct, rtMs))

        if correct {
            session.correctInPhase += 1

            updateLogMAR(session: session, direction: -1)
        } else {
            updateLogMAR(session: session, direction: +1)
        }

        updateConfidence(session: session, correct: correct, rtMs: rtMs)

        if phase == .gatekeeper {
            if correct {
                session.phase = .tumblingE
            } else {
                session.phase = .completed
            }
        }
    }

    func shouldStopPhase(session: VisionTestSession) -> Bool {

        switch session.phase {

        case .tumblingE:
            return session.trials >= 20 || session.reversalCount >= 6

        case .sloan10:
            return session.trials >= 12 || session.reversalCount >= 4

        default:
            return false
        }
    }

    func finalizePhase(session: VisionTestSession) {

        if session.phase == .tumblingE {
            if session.correctInPhase >= 10 && session.confidence >= 0.6 {
                session.sloanEligible = true
            }
        }
    }

    func maybeSwitchToSloan(session: VisionTestSession) {

        if session.phase == .tumblingE && session.sloanEligible {
            session.phase = .sloan10
            session.trials = 0
            session.reversalCount = 0
            session.stepSize = 0.05
        } else {
            session.phase = .completed
        }
    }

    func finalizeSession(session: VisionTestSession) -> TestOutcome {

        let valid =
            session.confidence >= 0.5 &&
            session.correctInPhase >= 5

        let passed =
            valid &&
            session.currentLogMAR <= 0.3

        return TestOutcome(
            estimatedLogMAR: session.currentLogMAR,
            confidence: valid ? session.confidence : nil,
            isValid: valid,
            passed: passed
        )
    }


    // MARK: - Internal Helpers

    private func updateLogMAR(session: VisionTestSession, direction: Int) {

        if direction != session.lastDirection {
            session.reversalCount += 1
        }

        session.lastDirection = direction
        session.currentLogMAR += Double(direction) * session.stepSize
        session.currentLogMAR = max(-0.2, min(1.2, session.currentLogMAR))
    }

    private func updateConfidence(
        session: VisionTestSession,
        correct: Bool,
        rtMs: Int
    ) {

        if !correct {
            session.confidence -= 0.05
        }

        if rtMs < 250 {
            session.confidence -= 0.03
        }

        session.confidence = max(0.0, min(1.0, session.confidence))
    }

    private func randomDirection() -> String {
        return ["up","down","left","right"].randomElement()!
    }
}
