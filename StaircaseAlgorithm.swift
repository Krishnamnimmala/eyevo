import Foundation

/// Adaptive staircase using screening-safe logic:
/// - 2 consecutive correct → harder (smaller optotype)
/// - 2 consecutive incorrect → easier (larger optotype)
/// - Step size shrinks near threshold (after a couple reversals)
/// - Reversal counted only when direction flips
final class StaircaseAlgorithm: AdaptiveAlgorithm {

    // MARK: - Session Initialization

    func start(session: VisionTestSession) {
        session.correctStreak = 0
        session.incorrectStreak = 0
        session.reversalCount = 0
        session.reversalLogMARs.removeAll()
        session.lastStepDirection = nil
    }

    // MARK: - Protocol Entry Point

    func update(session: VisionTestSession, correct: Bool, rtMs: Int) {
        applyUpdate(session: session, correct: correct)

        print(
            "STAIRCASE:",
            "correct:", correct,
            "logMAR:", String(format: "%.2f", session.currentLogMAR),
            "reversals:", session.reversalCount,
            "correctStreak:", session.correctStreak,
            "incorrectStreak:", session.incorrectStreak
        )
    }

    // MARK: - Core Staircase Logic

    private func applyUpdate(session: VisionTestSession, correct: Bool) {

        // 1️⃣ Adaptive step size (coarse early, fine near threshold)
        let step: Double = {
            if session.reversalCount >= 2 {
                return 0.05
            } else {
                return session.stepSize   // e.g. 0.20
            }
        }()

        let current = session.currentLogMAR
        var next = current
        var stepDirection: Int? = nil   // -1 = harder, +1 = easier

        // 2️⃣ Update streak counters
        if correct {
            session.correctStreak += 1
            session.incorrectStreak = 0
        } else {
            session.incorrectStreak += 1
            session.correctStreak = 0
        }

        // 3️⃣ Apply 2-correct / 2-wrong rule
        if session.correctStreak >= 2 {
            next = current - step
            stepDirection = -1
            session.correctStreak = 0
        } else if session.incorrectStreak >= 2 {
            next = current + step
            stepDirection = +1
            session.incorrectStreak = 0
        } else {
            // No movement until we get 2 in a row
            next = current
            stepDirection = nil
        }

        // 4️⃣ Clamp (safe screening bounds)
        next = max(-0.2, min(1.2, next))

        // 5️⃣ Reversal detection (direction flips)
        if let newDir = stepDirection {
            if let lastDir = session.lastStepDirection, newDir != lastDir {
                session.reversalCount += 1
                session.reversalLogMARs.append(current)
            }
            session.lastStepDirection = newDir
        }

        // 6️⃣ Commit the NEW value (this was the bug in your file)
        session.currentLogMAR = next
    }
}

