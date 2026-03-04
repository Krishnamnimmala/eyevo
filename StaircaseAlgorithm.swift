import Foundation

/// Adaptive staircase:
/// - 2 consecutive correct → harder (smaller optotype)
/// - 1 incorrect → easier (larger optotype)
/// - Step size shrinks after first reversal
/// - Threshold estimated from last 4 reversals
final class StaircaseAlgorithm: AdaptiveAlgorithm {

    // MARK: - Session Initialization

    func start(session: VisionTestSession) {
        session.correctStreak = 0
        session.reversalCount = 0
        session.reversalLogMARs.removeAll()
        session.lastStepDirection = nil
    }

    // MARK: - Protocol Entry Point

    func update(session: VisionTestSession, correct: Bool, rtMs: Int) {
        applyUpdate(session: session, correct: correct)

        print(
            "STAIRCASE →",
            "logMAR:", String(format: "%.2f", session.currentLogMAR),
            "reversals:", session.reversalCount,
            "correctStreak:", session.correctStreak
        )
    }

    // MARK: - Core Staircase Logic (2-down / 1-up)

    private func applyUpdate(session: VisionTestSession, correct: Bool) {

        // 1️⃣ Adaptive step size
        // Shrink after first reversal for smoother convergence
        let step: Double = {
            if session.reversalCount >= 1 {
                return 0.05
            } else {
                return session.stepSize   // e.g. 0.20
            }
        }()

        let current = session.currentLogMAR
        var next = current
        var stepDirection: Int? = nil   // -1 = harder, +1 = easier

        // 2️⃣ 2-down rule
        if correct {
            session.correctStreak += 1

            if session.correctStreak >= 2 {
                next = current - step
                stepDirection = -1
                session.correctStreak = 0
            }

        } else {
            // 3️⃣ 1-up rule
            session.correctStreak = 0
            next = current + step
            stepDirection = +1
        }

        // 4️⃣ Clamp bounds (screening-safe)
        next = max(-0.2, min(1.2, next))

        // 5️⃣ Reversal detection
        if let newDir = stepDirection {

            if let lastDir = session.lastStepDirection,
               newDir != lastDir {

                session.reversalCount += 1
                session.reversalLogMARs.append(current)

                print("🔁 REVERSAL \(session.reversalCount) at logMAR \(String(format: "%.2f", current))")
            }

            session.lastStepDirection = newDir
        }

        // 6️⃣ Commit new value
        session.currentLogMAR = next
    }
}

