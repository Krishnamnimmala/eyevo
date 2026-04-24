import Foundation

/// Adaptive staircase:
/// - Arrow phase: 2-down / 1-up
/// - Landolt-C phase: 1-up / 1-down with smaller step
/// - Step size decays with reversals
/// - Landolt-C does not go below 0.0 logMAR for handheld near testing
/// - Reversals are tracked only when an actual step occurs
final class StaircaseAlgorithm: AdaptiveAlgorithm {

    func start(session: VisionTestSession) {
        session.correctStreak = 0
        session.reversalCount = 0
        session.reversalLogMARs.removeAll()
        session.lastStepDirection = nil
    }

    func update(session: VisionTestSession, correct: Bool, rtMs: Int) {
        applyUpdate(session: session, correct: correct)

        print(
            "STAIRCASE →",
            "logMAR:", String(format: "%.2f", session.currentLogMAR),
            "reversals:", session.reversalCount,
            "correctStreak:", session.correctStreak,
            "step:", String(format: "%.2f", currentStepSize(for: session)),
            "isLandolt:", session.hasEnteredLandoltC
        )
    }

    private func applyUpdate(session: VisionTestSession, correct: Bool) {
        let isLandolt = session.hasEnteredLandoltC
        let step = currentStepSize(for: session)

        let current = session.currentLogMAR
        var next = current
        var stepDirection: Int? = nil   // -1 harder, +1 easier

        if isLandolt {
            // Landolt-C phase:
            // use direct 1-up / 1-down with smaller steps for stability
            if correct {
                next = current - step
                stepDirection = -1
            } else {
                next = current + step
                stepDirection = +1
            }

            // Streak is not used in Landolt mode
            session.correctStreak = 0

        } else {
            // Arrow phase:
            // 2 consecutive correct -> harder
            // 1 incorrect -> easier
            if correct {
                session.correctStreak += 1

                if session.correctStreak >= 2 {
                    next = current - step
                    stepDirection = -1
                    session.correctStreak = 0
                }
            } else {
                session.correctStreak = 0
                next = current + step
                stepDirection = +1
            }
        }

        // Clamp differently for Landolt vs Arrow
        let lowerBound = isLandolt ? 0.0 : -0.2
        let upperBound = 1.2
        next = max(lowerBound, min(upperBound, next))

        // Reversal tracking only when a real step happened
        if let newDir = stepDirection {
            if let lastDir = session.lastStepDirection, newDir != lastDir {
                session.reversalCount += 1
                session.reversalLogMARs.append(current)

                print("🔁 REVERSAL \(session.reversalCount) at logMAR \(String(format: "%.2f", current))")
            }

            session.lastStepDirection = newDir
        }

        session.currentLogMAR = next
    }

    private func currentStepSize(for session: VisionTestSession) -> Double {
        if session.hasEnteredLandoltC {
            switch session.reversalCount {
            case 0...1:
                return 0.10
            default:
                return 0.05
            }
        } else {
            switch session.reversalCount {
            case 0:
                return 0.20
            case 1...2:
                return 0.10
            default:
                return 0.05
            }
        }
    }
}
