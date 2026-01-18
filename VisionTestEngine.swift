import Foundation

final class VisionTestEngine {

    // MARK: - Constants

    private let sloanLetters = ["C","D","H","K","N","O","R","S","V","Z"]

    // Auto-switch policy parameters
    private let warmupTrials = 4
    private let accuracyThreshold = 0.75
    private let fallbackAccuracyThreshold = 0.35
    private let recentWindow = 6
    // New diagnostic thresholds (posterior entropy -> confidence)
    private let diagnosticThreshold = 0.55
    private let fallbackDiagnosticThreshold = 0.28

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
            optotype: .tumblingE,
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

        maybeAutoSwitch(session: session)
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

    private func maybeAutoSwitch(session: VisionTestSession) {
        // Only consider switching during running phases
        guard session.phase == .tumblingE || session.phase == .sloan10 else { return }

        let total = session.totalTrials
        let acc = recentAccuracy(session: session)
        let diag = algorithm.diagnosticConfidence(session: session)

        // If currently staircase, consider switching to QUEST when warmup satisfied and diagnostic confidence high
        if type(of: algorithm) == StaircaseAlgorithm.self {
            if total >= warmupTrials && (diag >= diagnosticThreshold || acc >= accuracyThreshold) {
                // Switch to QUEST
                let q = QuestAlgorithm()
                TelemetryManager.shared.record(event: "auto_switch_attempt", metadata: ["from": "Staircase", "to": "Quest", "acc": acc, "diag": diag, "total": total])
                switchAlgorithm(to: q, session: session)
                print("Auto-switched to QUEST (diag=\(String(format: "%.3f", diag)), acc=\(String(format: "%.3f", acc)), total=\(total))")
                TelemetryManager.shared.record(event: "auto_switch", metadata: ["from": "Staircase", "to": "Quest", "acc": acc, "diag": diag, "total": total])
            }
        } else {
            // If currently QUEST, fall back to staircase when diagnostic confidence collapses or accuracy collapses
            if total >= warmupTrials && (diag <= fallbackDiagnosticThreshold || acc <= fallbackAccuracyThreshold) {
                let s = StaircaseAlgorithm()
                TelemetryManager.shared.record(event: "auto_switch_attempt", metadata: ["from": "Quest", "to": "Staircase", "acc": acc, "diag": diag, "total": total])
                switchAlgorithm(to: s, session: session)
                print("Auto-fallback to Staircase (diag=\(String(format: "%.3f", diag)), acc=\(String(format: "%.3f", acc)), total=\(total))")
                TelemetryManager.shared.record(event: "auto_switch", metadata: ["from": "Quest", "to": "Staircase", "acc": acc, "diag": diag, "total": total])
            }
        }
    }
}
