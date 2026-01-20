import Foundation

final class VisionTestEngine {

    // MARK: - Constants

    private let sloanLetters = ["C","D","H","K","N","O","R","S","V","Z"]

    // MARK: - Session Lifecycle

    func startSession() -> VisionTestSession {
        let s = VisionTestSession()
        s.phase = .gatekeeper
        s.currentLogMAR = 0.8
        s.confidence = 1.0
        s.trials = 0
        s.trialsInPhase = 0
        s.totalTrials = 0
        return s
    }

    // MARK: - Stimulus Generation

    func nextStimulus(session: VisionTestSession) -> Stimulus {
        print("ENGINE nextStimulus ENTER → phase =", session.phase)

        return Stimulus(
            phase: session.phase,
            optotype: Optotype.tumblingE,
            symbol: "E",
            expectedAnswer: randomDirection(),
            sizeLogMAR: session.currentLogMAR
        )


    }
    
    // MARK: - Response Handling (QUEST / Staircase)

    func submitResponse(
        session: VisionTestSession,
        direction: ResponseDirection,
        phase: TestPhase,
        correct: Bool,
        rtMs: Int
    ){
        print("SUBMIT RESPONSE → phase before = \(session.phase)")
    
        session.trials += 1
        session.trialsInPhase += 1
        session.totalTrials += 1

        session.responses.append((correct: correct, rtMs: rtMs))
        if correct { session.correctInPhase += 1 }
        
            updateLogMAR(session: session, correct: correct)
            updateConfidence(session: session, correct: correct, rtMs: rtMs)
        if shouldStopPhase(session: session) {
                finalizePhase(session: session)
                maybeSwitchToSloan(session: session)
        
        // 🚪 Gatekeeper exit (formal, audit-friendly)
            if session.phase == .gatekeeper {
                session.phase = .tumblingE
                session.resetPhaseCounters()
            }
            print("SUBMIT RESPONSE → phase after = \(session.phase)")
            
        }

        // 🔑 FIX: Exit Gatekeeper immediately after first response
        if session.phase == .gatekeeper {
            session.phase = .tumblingE
            session.resetPhaseCounters()
            session.stepSize = 0.1
            return
        }

        updateLogMAR(session: session, correct: correct)
        updateConfidence(session: session, correct: correct, rtMs: rtMs)

        if shouldStopPhase(session: session) {
            finalizePhase(session: session)
            maybeSwitchToSloan(session: session)
        }
    }

    // MARK: - Phase Control

    func shouldStopPhase(session: VisionTestSession) -> Bool {

        switch session.phase {
        case .tumblingE:
            return session.trialsInPhase >= 20 || session.reversalCount >= 6
        case .sloan10:
            return session.trialsInPhase >= 12 || session.reversalCount >= 4
        default:
            return false
        }
    }

    func finalizePhase(session: VisionTestSession) {

        if session.phase == .tumblingE {
            if session.correctInPhase >= 10 && session.confidence >= 0.6 {
                session.sloanEligible = true
                session.tumblingEResultLogMAR = session.currentLogMAR
            }
        }

        if session.phase == .sloan10 {
            session.sloanResultLogMAR = session.currentLogMAR
        }
    }

    func maybeSwitchToSloan(session: VisionTestSession) {

        if session.phase == .tumblingE && session.sloanEligible {
            session.phase = .sloan10
            session.resetPhaseCounters()
            session.stepSize = 0.05
        } else {
            session.complete()
        }
    }

    // MARK: - Finalization

    func finalizeSession(session: VisionTestSession) -> TestOutcome {

        let valid = session.totalTrials >= 6
        let finalLogMAR = session.sloanResultLogMAR ?? session.tumblingEResultLogMAR
        let passed = valid && (finalLogMAR ?? 1.0) <= 0.3

        return TestOutcome(
            estimatedLogMAR: valid ? finalLogMAR : nil,
            confidence: valid ? session.confidence : nil,
            isValid: valid,
            passed: passed
        )
    }

    // MARK: - Internal Helpers

    private func updateLogMAR(session: VisionTestSession, correct: Bool) {

        let direction = correct ? -1 : 1

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

        if !correct { session.confidence -= 0.05 }
        if rtMs < 250 { session.confidence -= 0.03 }

        session.confidence = max(0.0, min(1.0, session.confidence))
    }

    private func randomDirection() -> ResponseDirection {
        ResponseDirection.allCases.randomElement() ?? .up
    }

    // Optional telemetry helper: record a session end event if TelemetryManager exists and is available in target.
    private func recordSessionEndTelemetry(outcome: TestOutcome) {
        // Coerce estimatedLogMAR into an `Any` before coalescing to avoid Double?/NSNull mismatches
        let est: Any = (outcome.estimatedLogMAR as Any?) ?? NSNull()

        // Post a telemetry notification (TelemetryManager can subscribe if present) and also print locally.
        let payload: [String: Any] = ["event": "session_end", "isValid": outcome.isValid, "passed": outcome.passed, "estimatedLogMAR": est]

        // Post notification so a debug-only TelemetryManager (if running) can record it without requiring a compile-time dependency.
        NotificationCenter.default.post(name: Notification.Name("EYEVO.telemetry.record"), object: nil, userInfo: payload)

        // Also print for immediate debug visibility.
        print("[Telemetry] \(payload)")
    }
}
