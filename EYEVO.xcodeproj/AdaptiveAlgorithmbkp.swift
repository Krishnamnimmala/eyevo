import Foundation

// StaircaseAlgorithm implementation only (AdaptiveAlgorithm protocol is defined in VisionCoreModels.swift)

final class StaircaseAlgorithm: AdaptiveAlgorithm {

    // Runtime-controlled verbose logging: check UserDefaults then environment
    private static var verboseFlag: Bool {
        let ud = UserDefaults.standard
        if ud.object(forKey: "debug.staircaseVerbose") != nil {
            return ud.bool(forKey: "debug.staircaseVerbose")
        }
        let v = ProcessInfo.processInfo.environment["STAIRCASE_VERBOSE"] ?? ""
        return v.lowercased() == "1" || v.lowercased() == "true"
    }

    // Runtime-controlled default step size (can be overridden with env var STAIRCASE_STEP, e.g. "0.08")
    private static var defaultStepSize: Double {
        // First check UserDefaults (in-app debug panel)
        let ud = UserDefaults.standard
        let u = ud.double(forKey: "debug.staircaseStep")
        if u > 0 {
            return u
        }
        // Next check environment
        if let raw = ProcessInfo.processInfo.environment["STAIRCASE_STEP"], let d = Double(raw) {
            return d
        }
        return 0.08
    }

    func start(session: VisionTestSession) {
        // Ensure session defaults for staircase (use UD or env override if present)
        session.stepSize = StaircaseAlgorithm.defaultStepSize
        // do not clear session counters here — startSession already creates a fresh session
        session.reversalCount = 0
        session.lastDirection = 0
        session.consecutiveCorrect = 0
        // note: we intentionally do not remove session.responses here
    }

    func initializeFromSession(session: VisionTestSession) {
        // When switching to staircase mid-session, respect current step size and counters
        // but do not clear historical responses.
        // Ensure step size has a reasonable default
        if session.stepSize <= 0 { session.stepSize = 0.1 }
        if session.consecutiveCorrect < 0 { session.consecutiveCorrect = 0 }
    }

    func update(session: VisionTestSession, correct: Bool, rtMs: Int) {
        // Bookkeeping for trials and responses
        session.responses.append((correct: correct, rtMs: rtMs))
        session.trials += 1
        session.trialsInPhase += 1
        session.totalTrials += 1

        if correct {
            session.correctInPhase += 1
            session.consecutiveCorrect += 1
        } else {
            session.consecutiveCorrect = 0
        }

        // Confidence: penalize incorrect only (no ordinary RT penalty here)
        if !correct {
            session.confidence -= 0.05
        }
        session.confidence = max(0.0, min(1.0, session.confidence))

        // 2-down/1-up logic: only change size on 2 consecutive corrects (down) or any incorrect (up)
        var stepDirection = 0 // -1 => decrease (harder/smaller), +1 => increase (easier/larger)

        if !correct {
            stepDirection = 1
        } else if session.consecutiveCorrect >= 2 {
            stepDirection = -1
            // consume the two-correct event
            session.consecutiveCorrect = 0
        }

        // Apply staircase step only when a directional step occurs
        if stepDirection != 0 {
            if stepDirection != session.lastDirection && session.lastDirection != 0 {
                session.reversalCount += 1
            }
            session.lastDirection = stepDirection
            session.currentLogMAR += Double(stepDirection) * session.stepSize
            session.currentLogMAR = max(-0.2, min(1.2, session.currentLogMAR))
        }

        // Verbose debug logging for staircase behavior (guarded by UD/env flag)
        if StaircaseAlgorithm.verboseFlag {
            let directionStr: String
            if stepDirection == -1 { directionStr = "DOWN" } else if stepDirection == 1 { directionStr = "UP" } else { directionStr = "NO_STEP" }
            print("[STAIRCASE] trial=", session.totalTrials,
                  "correct=", correct,
                  "rtMs=", rtMs,
                  "dir=", directionStr,
                  "consecCorrect=", session.consecutiveCorrect,
                  "currentLogMAR=", String(format: "%.3f", session.currentLogMAR),
                  "reversals=", session.reversalCount,
                  "confidence=", String(format: "%.3f", session.confidence))
        }
    }

    func nextSize(session: VisionTestSession) -> Double {
        return session.currentLogMAR
    }
}
