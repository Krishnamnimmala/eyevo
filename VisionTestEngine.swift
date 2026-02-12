import Foundation
import CoreGraphics

final class VisionTestEngine {

    // MARK: - Adaptive Algorithm (Injected)
    private let algorithm: AdaptiveAlgorithm?

    init(algorithm: AdaptiveAlgorithm? = nil) {
        self.algorithm = algorithm
    }

    // MARK: - Session Lifecycle

    func startSession() -> VisionTestSession {
        let s = VisionTestSession()

        // Phase + threshold
        s.phase = .gatekeeper
        s.currentLogMAR = 0.8

        // Confidence starts optimistic
        s.confidence = 1.0

        // Counters
        s.trials = 0
        s.trialsInPhase = 0
        s.totalTrials = 0
        s.correctInPhase = 0

        // Staircase defaults
        s.stepSize = 0.20
        s.reversalCount = 0
        s.reversalLogMARs.removeAll()

        // Modes (Arrow-only here; UI switches optotype)
        s.optotypeMode = .arrows
        s.distanceMode = .near

        algorithm?.start(session: s)
        return s
    }

    // MARK: - Stimulus Generation (Arrow → Landolt-C locked)

    func nextStimulus(session: VisionTestSession) -> Stimulus {
        let pxPerMM = session.pxPerMM ?? 6.0
        let pixelSize = computeOptotypePixelHeight(
            logMAR: session.currentLogMAR,
            distanceMode: session.distanceMode,
            pxPerMM: pxPerMM
        )
        print(
          "ENGINE SIZE → logMAR=\(session.currentLogMAR) " +
          "pxPerMM=\(pxPerMM) " +
          "pixelSize=\(pixelSize)"
        )

        let opening = randomDirection()

        let landoltThresholdLogMAR: Double = 0.6

        let optotype: Stimulus.Optotype
        if session.hasEnteredLandoltC || session.currentLogMAR <= landoltThresholdLogMAR {
            optotype = .landoltC
            session.hasEnteredLandoltC = true
        } else {
            optotype = .arrows
        }

            return Stimulus(
                phase: session.phase,
                optotype: optotype,
                openingDirection: opening,
                symbol: "▲", // UI can ignore for Landolt-C
                sizeLogMAR: session.currentLogMAR,
                pixelSize: pixelSize
            )
        }

    // MARK: - Response Handling

    func submitResponse(
        session: VisionTestSession,
        direction: ResponseDirection,
        phase: TestPhase,
        correct: Bool,
        rtMs: Int
    ) {
        // Record response
        session.trials += 1
        session.trialsInPhase += 1
        session.totalTrials += 1
        session.responses.append((correct: correct, rtMs: rtMs))
        if correct { session.correctInPhase += 1 }


        // Adaptive update
        if let alg = algorithm {
            alg.update(session: session, correct: correct, rtMs: rtMs)
        } else {
            internalAdaptiveUpdate(session: session, correct: correct)
        }

        // Update confidence
        session.confidence = computeConfidence(session: session)

        // Stop decision
        if shouldStop(session: session) {
            
            print("STOP → trials=\(session.totalTrials), reversals=\(session.reversalCount), logMAR=\(session.currentLogMAR)")

            session.complete()
        }
    }

    // MARK: - STOP RULE (AUTO-EXTEND FIXED)

    private func shouldStop(session: VisionTestSession) -> Bool {

        // 🔒 HARD SAFETY CAP (never infinite)
        if session.totalTrials >= 25 { return true }

        // ❗ DO NOT STOP until we reach true acuity zone
        if session.currentLogMAR > 0.3 {
            // optional: if user is wildly inconsistent early, you can stop at 20
                    return session.totalTrials >= 20 && session.reversalCount >= 3
                }
        

        // ---- We are in Landolt-C zone ----
            // We want enough threshold evidence, not just easy correctness.

            let hasGoodEvidence =
                session.reversalCount >= 5 && session.totalTrials >= 18

            // soft stop if evidence is decent by 20
            let hasDecentEvidence =
                session.reversalCount >= 4 && session.totalTrials >= 20

            return hasGoodEvidence || hasDecentEvidence
        }
    
    

        
    // MARK: - Confidence Estimation

    func computeConfidence(session: VisionTestSession) -> Double {
        let total = session.totalTrials
        let reversals = session.reversalCount

        let accuracy: Double = {
            guard total > 0 else { return 0.0 }
            let correctCount = session.responses.filter { $0.correct }.count
            return Double(correctCount) / Double(total)
        }()

        // ⛔ Minimum evidence guard (FDA-safe)
            guard total >= 8 else {
                return min(0.35, accuracy)
            }

        // 🔁 Reversal-based convergence score
            let reversalScore: Double = {
                switch reversals {
                case 0...1: return 0.30
                case 2...3: return 0.50
                case 4...5: return 0.75
                default:    return 0.90
                }
            }()
        
        // 📊 Trial evidence score
            let trialScore = min(Double(total) / 12.0, 1.0)

        // ⭐ Landolt-C bonus (ONLY near true acuity zone)
            let landoltBonus: Double = {
                guard session.currentLogMAR <= 0.3 else { return 0.0 }
                return min(0.10, Double(reversals) * 0.02)
            }()
        
        // 🧠 Conservative but rewarding blend
            let raw =
                (0.40 * accuracy) +
                (0.40 * reversalScore) +
                (0.15 * trialScore) +
                landoltBonus

            // 🔒 Clamp (never imply certainty)
            return min(max(raw, 0.0), 0.95)
        }

    // MARK: - Optotype Sizing

    private func computeOptotypePixelHeight(
        logMAR: Double,
        distanceMode: TestDistanceMode,
        pxPerMM: Double
    ) -> CGFloat {

        let viewingDistanceMM: Double = {
            switch distanceMode {
            case .near:         return 400.0
            case .intermediate: return 700.0
            case .far:          return 2000.0
            }
        }()

        let mar = pow(10.0, logMAR)
        let totalArcMinutes = 5.0 * mar
        let arcRadians = totalArcMinutes * (.pi / (180.0 * 60.0))

        let physicalHeightMM = viewingDistanceMM * tan(arcRadians)
        let pixels = physicalHeightMM * pxPerMM

        return CGFloat(pixels)
    }


    // MARK: - Fallback Adaptive Logic

    private func internalAdaptiveUpdate(session: VisionTestSession, correct: Bool) {
        let step = session.stepSize
        let next = session.currentLogMAR + (correct ? -step : step)
        session.currentLogMAR = max(-0.2, min(1.2, next))
    }

    // MARK: - Helpers

    private func randomDirection() -> ResponseDirection {
        ResponseDirection.allCases.randomElement() ?? .up
    }
}

