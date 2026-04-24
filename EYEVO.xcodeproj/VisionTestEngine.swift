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

        // Modes
        s.optotypeMode = .arrows
        s.distanceMode = .near

        // 👁 Eye control
        s.currentEye = .left
        s.didEnforceForCurrentEye = false
        s.isTestingSecondEye = false

        // Per-eye results (if your session has them)
        // If not present, add these vars in VisionTestSession:
        // var leftEyeLogMAR: Double?
        // var rightEyeLogMAR: Double?
        // var leftEyePassed: Bool?
        // var rightEyePassed: Bool?
        s.leftEyeLogMAR = nil
        s.rightEyeLogMAR = nil
        s.leftEyePassed = nil
        s.rightEyePassed = nil

        algorithm?.start(session: s)
        
        // 🔊 Speak first eye instruction
        AudioManager.shared.speak("Please cover your right eye. Starting left eye test.")
        
        return s
    }

    // MARK: - Stimulus Generation

    func nextStimulus(session: VisionTestSession) -> Stimulus {

        let pxPerMM = session.pxPerMM ?? 6.0

        let pixelSize = computeOptotypePixelHeight(
            logMAR: session.currentLogMAR,
            distanceMode: session.distanceMode,
            pxPerMM: pxPerMM
        )

        print("ENGINE SIZE → logMAR=\(session.currentLogMAR) pxPerMM=\(pxPerMM) pixelSize=\(pixelSize) eye=\(session.currentEye.rawValue)")

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
            symbol: "▲",
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
        // Counters
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

        // Confidence update
        session.confidence = computeConfidence(session: session)

        // Stop decision
        if shouldStop(session: session) {
            handleEyeTransition(session: session)
        }
    }

    // MARK: - Threshold Convergence (Reversal Mean)

    /// Computes threshold as mean of last 4 reversal logMARs.
    /// Returns nil if not enough reversals.
    private func estimatedThresholdLogMAR(session: VisionTestSession) -> Double? {
        let r = session.reversalLogMARs
        guard r.count >= 4 else { return nil }
        let tail = r.suffix(4)
        let mean = tail.reduce(0.0, +) / Double(tail.count)
        return mean
    }

    // MARK: - 👁 Eye Switching Logic

    private func handleEyeTransition(session: VisionTestSession) {

        if !session.isTestingSecondEye {

            // Save LEFT eye result
            session.leftEyeLogMAR = session.currentLogMAR
            session.leftEyePassed = session.currentLogMAR <= 0.3

            AudioManager.shared.speak("Left eye complete. Please cover your left eye. Now testing right eye.")

            session.isTestingSecondEye = true
            session.currentEye = .right
            session.didEnforceForCurrentEye = false

            resetForNextEye(session: session)

        } else {

            // Save RIGHT eye result
            session.rightEyeLogMAR = session.currentLogMAR
            session.rightEyePassed = session.currentLogMAR <= 0.3

            AudioManager.shared.speak("Right eye complete. Screening finished.")

            session.testEndTime = Date()
            session.complete()
        }
    }

    private func resetForNextEye(session: VisionTestSession) {

        // Reset difficulty
        session.currentLogMAR = 0.8
        session.stepSize = 0.20
        session.hasEnteredLandoltC = false

        // Reset counters PER EYE
        session.trials = 0
        session.trialsInPhase = 0
        session.correctInPhase = 0
        session.totalTrials = 0

        // Reset reversal tracking
        session.reversalCount = 0
        session.reversalLogMARs.removeAll()

        // ✅ Reset responses so accuracy/confidence is per-eye (recommended)
        session.responses.removeAll()

        algorithm?.start(session: session)
    }

    // MARK: - STOP RULE (Convergence Required)

    private func shouldStop(session: VisionTestSession) -> Bool {

        // Safety hard cap per eye
        if session.trialsInPhase >= 25 { return true }

        // Do not stop early without enough evidence
        if session.trialsInPhase < 20 { return false }

        // Require reversals for convergence
        if session.reversalCount < 4 { return false }

        // Converged
        return true
    }

    // MARK: - Confidence

    func computeConfidence(session: VisionTestSession) -> Double {

        let total = session.totalTrials
        let reversals = session.reversalCount

        let accuracy: Double = {
            guard total > 0 else { return 0.0 }
            let correctCount = session.responses.filter { $0.correct }.count
            return Double(correctCount) / Double(total)
        }()

        // Minimum evidence guard
        guard total >= 8 else { return min(0.35, accuracy) }

        let reversalScore: Double = {
            switch reversals {
            case 0...1: return 0.30
            case 2...3: return 0.55
            case 4...5: return 0.80
            default:    return 0.90
            }
        }()

        let trialScore = min(Double(total) / 12.0, 1.0)

        // Conservative clamp if not converged
        let convergenceClamp: Double = (reversals < 4) ? 0.70 : 0.95

        let raw =
            (0.45 * accuracy) +
            (0.40 * reversalScore) +
            (0.15 * trialScore)

        return min(max(raw, 0.0), convergenceClamp)
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

    // MARK: - Fallback Adaptive

    private func internalAdaptiveUpdate(session: VisionTestSession, correct: Bool) {
        let step = session.stepSize
        let next = session.currentLogMAR + (correct ? -step : step)
        session.currentLogMAR = max(-0.2, min(1.2, next))
    }

    private func randomDirection() -> ResponseDirection {
        ResponseDirection.allCases.randomElement() ?? .up
    }
}

