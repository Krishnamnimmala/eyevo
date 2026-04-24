
import Foundation
import CoreGraphics

final class VisionTestEngine {

    // MARK: - Reliability Tracking

    private(set) var notSureCount: Int = 0
    private(set) var totalResponses: Int = 0
    private(set) var consecutiveNotSureCount: Int = 0
    private(set) var maxConsecutiveNotSureCount: Int = 0

    // MARK: - Threshold Confirmation

    private let thresholdConfirmationLogMAR: Double = 0.0
    private let thresholdConfirmationTrialsRequired: Int = 3

    // MARK: - Stop / Evidence Tuning

    private let minTrialsBeforeStop: Int = 12
    private let normalArrowMaxTrials: Int = 12
    private let preferredLandoltReversals: Int = 3
    private let minimumLandoltReversalsForPass: Int = 2
    private let minimumLandoltReversalsForStableStop: Int = 2
    private let landoltFallbackMaxTrials: Int = 16

    // MARK: - Private State

    private let algorithm: AdaptiveAlgorithm?
    private var lastDirection: ResponseDirection?

    init(algorithm: AdaptiveAlgorithm? = nil) {
        self.algorithm = algorithm
    }

    // MARK: - Session Lifecycle

    func startSession() -> VisionTestSession {
        resetReliabilityCounters()

        let s = VisionTestSession()

        s.phase = .gatekeeper
        s.currentLogMAR = 0.8
        s.confidence = 1.0

        s.trials = 0
        s.trialsInPhase = 0
        s.totalTrials = 0
        s.correctInPhase = 0

        s.stepSize = 0.20
        s.reversalCount = 0
        s.reversalLogMARs = []

        s.optotypeMode = .arrows
        s.distanceMode = .near

        s.currentEye = Eye.left
        s.didEnforceForCurrentEye = false
        s.isTestingSecondEye = false

        s.leftEyeLogMAR = nil
        s.rightEyeLogMAR = nil
        s.leftEyePassed = nil
        s.rightEyePassed = nil

        s.hasEnteredLandoltC = false
        s.responses = []
        s.thresholdConfirmation.reset()

        algorithm?.start(session: s)

        AudioManager.shared.speak("Please cover your right eye. Starting left eye test.")
        return s
    }

    // MARK: - Stimulus Generation

    func nextStimulus(session: VisionTestSession) -> Stimulus {
        let pxPerMM = session.pxPerMM ?? CalibrationStore.shared.pxPerMM ?? 6.0
        let opening = randomDirection()

        let landoltThresholdLogMAR: Double = 0.35

        let optotype: Stimulus.Optotype
        if session.hasEnteredLandoltC || session.currentLogMAR < landoltThresholdLogMAR {
            optotype = .landoltC
            session.hasEnteredLandoltC = true
        } else {
            optotype = .arrows
        }

        let viewingDistanceMM: Double = {
            switch session.distanceMode {
            case .near: return 400
            case .intermediate: return 700
            case .far: return 2000
            }
        }()

        let pixelSize = OptotypeSizing.pixelHeight(
            logMAR: session.currentLogMAR,
            viewingDistanceMM: viewingDistanceMM,
            pxPerMM: pxPerMM,
            optotype: optotype
        )

        print("""
        [STIMULUS]
        eye: \(session.currentEye)
        phase: \(session.phase)
        logMAR: \(session.currentLogMAR)
        optotype: \(optotype)
        direction: \(opening)
        pxPerMM: \(pxPerMM)
        pixelSize: \(pixelSize)
        hasEnteredLandoltC: \(session.hasEnteredLandoltC)
        thresholdConfirmationActive: \(session.thresholdConfirmation.isActive)
        """)

        return Stimulus(
            phase: session.phase,
            optotype: optotype,
            openingDirection: opening,
            symbol: symbol(for: opening, optotype: optotype),
            sizeLogMAR: session.currentLogMAR,
            pixelSize: pixelSize
        )
    }

    // MARK: - Public Response Handling

    func submitResponse(
        session: VisionTestSession,
        direction: ResponseDirection,
        phase: TestPhase,
        correct: Bool,
        rtMs: Int
    ) {
        processResponse(
            session: session,
            direction: direction,
            phase: phase,
            correct: correct,
            rtMs: rtMs,
            wasNotSure: false
        )
    }

    func submitNotSure(
        session: VisionTestSession,
        phase: TestPhase,
        rtMs: Int
    ) {
        let fallbackDirection = lastDirection ?? .up

        processResponse(
            session: session,
            direction: fallbackDirection,
            phase: phase,
            correct: false,
            rtMs: rtMs,
            wasNotSure: true
        )
    }

    // MARK: - Core Response Processing

    private func processResponse(
        session: VisionTestSession,
        direction: ResponseDirection,
        phase: TestPhase,
        correct: Bool,
        rtMs: Int,
        wasNotSure: Bool
    ) {
        print("\n================ RESPONSE =================")
        print("[ENGINE] Before update logMAR =", session.currentLogMAR)
        print("[ENGINE] Step size =", session.stepSize)
        print("[ENGINE] Direction =", direction)
        print("[ENGINE] Correct =", correct)
        print("[ENGINE] Not Sure =", wasNotSure)
        print("[ENGINE] RT (ms) =", rtMs)

        totalResponses += 1
        updateNotSureTracking(wasNotSure: wasNotSure)

        // Not Sure does not count as valid threshold evidence.
        if wasNotSure {
            if consecutiveNotSureCount >= 2 {
                let easeStep = session.hasEnteredLandoltC ? 0.10 : session.stepSize
                session.currentLogMAR = min(1.2, session.currentLogMAR + easeStep)
            }

            session.confidence = computeConfidence(session: session)

            print("""
            [NOT SURE]
            notSureCount: \(notSureCount)
            totalResponses: \(totalResponses)
            notSureRatio: \(notSureRatio)
            consecutiveNotSureCount: \(consecutiveNotSureCount)
            adjustedLogMAR: \(session.currentLogMAR)
            confidence: \(session.confidence)
            reliability: \(reliabilityLabel(for: session.currentLogMAR))
            """)

            if shouldFloorStop(session: session) {
                print("[STOP RULE] floor-stop triggered by repeated Not Sure responses")
                handleEyeTransition(session: session)
            }

            print("===========================================\n")
            return
        }

        // Valid response accounting
        session.trials += 1
        session.trialsInPhase += 1
        session.totalTrials += 1

        session.responses.append((correct: correct, rtMs: rtMs))

        if correct {
            session.correctInPhase += 1
            session.correctStreak += 1
            session.incorrectStreak = 0
        } else {
            session.incorrectStreak += 1
            session.correctStreak = 0
        }

        if let alg = algorithm {
            alg.update(session: session, correct: correct, rtMs: rtMs)
        } else {
            internalAdaptiveUpdate(session: session, correct: correct)
        }

        if shouldStartThresholdConfirmation(session: session) {
            session.thresholdConfirmation.start(
                targetLogMAR: thresholdConfirmationLogMAR,
                requiredTrials: thresholdConfirmationTrialsRequired
            )
            print("[THRESHOLD CONFIRMATION] started at logMAR \(thresholdConfirmationLogMAR)")
        }

        let isHoldingForConfirmation = processThresholdConfirmationIfNeeded(
            session: session,
            correct: correct
        )

        applyReliabilityGuardIfNeeded(session: session)

        print("[ENGINE] After update logMAR =", session.currentLogMAR)

        session.confidence = computeConfidence(session: session)

        print("[ENGINE] Confidence =", session.confidence)
        print("[ENGINE] Reliability =", reliabilityLabel(for: session.currentLogMAR))
        print("[ENGINE] Trials in phase =", session.trialsInPhase)
        print("[ENGINE] Reversal count =", session.reversalCount)
        print("===========================================\n")

        if isHoldingForConfirmation {
            return
        }

        if shouldStop(session: session) {
            print("[ENGINE] STOP condition reached")
            handleEyeTransition(session: session)
        }
    }

    // MARK: - Threshold Confirmation

    private func shouldStartThresholdConfirmation(session: VisionTestSession) -> Bool {
        session.hasEnteredLandoltC &&
        !session.thresholdConfirmation.isActive &&
        session.currentLogMAR <= thresholdConfirmationLogMAR &&
        session.totalTrials >= 12 &&
        session.reversalCount >= 1
    }

    /// Returns true when the engine should keep testing and NOT evaluate normal stop rules yet.
    private func processThresholdConfirmationIfNeeded(
        session: VisionTestSession,
        correct: Bool
    ) -> Bool {
        guard session.thresholdConfirmation.isActive else { return false }

        session.thresholdConfirmation.record(correct: correct)

        print("""
        [THRESHOLD CONFIRMATION]
        targetLogMAR: \(session.thresholdConfirmation.targetLogMAR)
        completedTrials: \(session.thresholdConfirmation.completedTrials)
        correctTrials: \(session.thresholdConfirmation.correctTrials)
        requiredTrials: \(session.thresholdConfirmation.requiredTrials)
        incorrectStreak: \(session.incorrectStreak)
        """)

        if session.thresholdConfirmation.isSatisfied {
            print("[THRESHOLD CONFIRMATION] satisfied — allow normal stop/finalization")
            session.currentLogMAR = session.thresholdConfirmation.targetLogMAR
            session.thresholdConfirmation.reset()
            return false
        }

        if session.thresholdConfirmation.isFailed {
            print("[THRESHOLD CONFIRMATION] failed — back off from floor and continue")
            session.currentLogMAR = 0.10
            session.thresholdConfirmation.reset()
            return true
        }

        if session.incorrectStreak >= 2 {
            session.currentLogMAR = 0.10
        } else {
            session.currentLogMAR = session.thresholdConfirmation.targetLogMAR
        }

        return true
    }

    // MARK: - Eye Switching

    private func handleEyeTransition(session: VisionTestSession) {
        let threshold = session.currentLogMAR
        let reliability = reliabilityLabel(for: threshold)

        let passed: Bool = {
            let thresholdPass = threshold <= 0.10
            let confidencePass = session.confidence >= 0.65
            let reliabilityPass = reliability == "High"

            // Special-case: perfect, stable floor performance should pass
            let strongFloorPass =
                threshold <= 0.0 &&
                notSureCount == 0 &&
                maxConsecutiveNotSureCount == 0 &&
                session.confidence >= 0.65 &&
                reliability == "High"

            if session.hasEnteredLandoltC {
                return strongFloorPass ||
                    (thresholdPass &&
                     confidencePass &&
                     reliabilityPass &&
                     session.reversalCount >= minimumLandoltReversalsForPass)
            } else {
                return thresholdPass && confidencePass && reliabilityPass
            }
        }()

        print("""
        [EYE TRANSITION]
        eye: \(session.currentEye)
        threshold logMAR: \(threshold)
        passed: \(passed)
        reliability: \(reliability)
        reversals: \(session.reversalCount)
        confidence: \(session.confidence)
        """)

        if !session.isTestingSecondEye {
            session.leftEyeLogMAR = threshold
            session.leftEyePassed = passed

            AudioManager.shared.speak("Left eye complete. Please cover your left eye. Now testing right eye.")

            session.isTestingSecondEye = true
            session.currentEye = Eye.right
            session.didEnforceForCurrentEye = false

            resetForNextEye(session: session)
        } else {
            session.rightEyeLogMAR = threshold
            session.rightEyePassed = passed

            AudioManager.shared.speak("Right eye complete. Screening finished.")

            session.testEndTime = Date()
            session.complete()
        }
    }

    private func resetForNextEye(session: VisionTestSession) {
        session.currentLogMAR = 0.8
        session.stepSize = 0.20
        session.hasEnteredLandoltC = false

        session.trials = 0
        session.trialsInPhase = 0
        session.correctInPhase = 0
        session.totalTrials = 0

        session.correctStreak = 0
        session.incorrectStreak = 0

        session.reversalCount = 0
        session.reversalLogMARs = []
        session.responses = []
        session.thresholdConfirmation.reset()

        resetReliabilityCounters()

        print("[RESET] Starting next eye with logMAR =", session.currentLogMAR)

        algorithm?.start(session: session)
    }

    // MARK: - Stop Rule

    private func shouldStop(session: VisionTestSession) -> Bool {
        if shouldFloorStop(session: session) {
            print("[STOP RULE] floor-stop triggered by severe early uncertainty")
            return true
        }

        if session.thresholdConfirmation.isActive {
            print("[STOP RULE] threshold confirmation active — continue testing")
            return false
        }

        if session.trialsInPhase < minTrialsBeforeStop {
            return false
        }

        if session.hasEnteredLandoltC {
            if session.reversalCount >= preferredLandoltReversals {
                print("[STOP RULE] Landolt-C reversalCount >= \(preferredLandoltReversals)")
                return true
            }

            let recent = session.responses.suffix(6)
            let correctCount = recent.filter { $0.correct }.count

            if session.reversalCount >= minimumLandoltReversalsForStableStop &&
                recent.count == 6 &&
                correctCount >= 5 &&
                reliabilityLabel(for: session.currentLogMAR) != "Low" {
                print("[STOP RULE] Landolt-C stable recent evidence with >= 2 reversals")
                return true
            }

            if session.trialsInPhase >= landoltFallbackMaxTrials {
                print("[STOP RULE] Landolt-C fallback max trials reached")
                return true
            }

            return false
        }

        if session.trialsInPhase >= normalArrowMaxTrials {
            print("[STOP RULE] Arrow max trials reached")
            return true
        }

        if session.reversalCount >= 4 {
            print("[STOP RULE] reversalCount >= 4")
            return true
        }

        return false
    }

    private func shouldFloorStop(session: VisionTestSession) -> Bool {
        if session.hasEnteredLandoltC {
            return maxConsecutiveNotSureCount >= 4
        }

        return totalResponses >= 8 &&
               session.currentLogMAR >= 0.8 &&
               notSureCount >= 5
    }

    // MARK: - Final Outcome

    func finalizeSession(session: VisionTestSession) -> TestOutcome {
        let start = session.testStartTime ?? Date()
        let end = session.testEndTime ?? Date()

        let finalConfidence = computeConfidence(session: session)
        let finalReliability = reliabilityLabel(
            for: max(session.leftEyeLogMAR ?? -9, session.rightEyeLogMAR ?? -9)
        )

        let total = max(totalResponses, 1)
        let notSureRate = Double(notSureCount) / Double(total)

        let leftLogMAR = session.leftEyeLogMAR
        let rightLogMAR = session.rightEyeLogMAR

        let hasBothEyes =
            leftLogMAR != nil &&
            rightLogMAR != nil

        // PASS threshold for final eye-level outcome
        let leftThresholdPass = (leftLogMAR ?? 99) <= 0.10
        let rightThresholdPass = (rightLogMAR ?? 99) <= 0.10

        // Strong quality needed for final PASS
        let qualityStrong =
            finalConfidence >= 0.65 &&
            finalReliability == "High" &&
            notSureRate <= 0.15 &&
            maxConsecutiveNotSureCount <= 3

        // Usable result, even if not PASS
        let qualityAcceptable =
            finalConfidence >= 0.50 &&
            finalReliability != "Low" &&
            notSureRate <= 0.35 &&
            maxConsecutiveNotSureCount <= 4

        // Special-case override:
        // perfect / near-perfect clean runs must not become RETEST
        let perfectPerformance =
            hasBothEyes &&
            (leftLogMAR ?? 99) <= 0.10 &&
            (rightLogMAR ?? 99) <= 0.10 &&
            finalConfidence >= 0.65 &&
            finalReliability == "High" &&
            notSureCount == 0 &&
            maxConsecutiveNotSureCount == 0 &&
            totalResponses >= 20

        // Final eye-level pass is recomputed from final threshold + final quality.
        // Also allow the perfect-performance override.
        let leftFinalPass = leftThresholdPass && (qualityStrong || perfectPerformance)
        let rightFinalPass = rightThresholdPass && (qualityStrong || perfectPerformance)

        // Validity:
        // - perfect clean runs are always valid
        // - otherwise require normal acceptable quality
        let isValid: Bool = {
            guard hasBothEyes else { return false }
            if perfectPerformance { return true }
            guard qualityAcceptable else { return false }
            return true
        }()

        let overallPassed = isValid && leftFinalPass && rightFinalPass

        let resultMode: ResultMode = isValid ? .threshold : .floorEstimate

        let interpretation: String = {
            if !isValid {
                return "Screening result is not reliable enough for a final decision. Retest is recommended under controlled conditions."
            }

            if overallPassed {
                return "Stable threshold obtained. Responses met screening criteria in both eyes."
            }

            if leftFinalPass != rightFinalPass {
                return "One eye met screening threshold while the other did not. Follow-up eye evaluation is recommended."
            }

            return "Screening suggests reduced visual acuity or inconsistent threshold performance. Follow-up eye evaluation is recommended."
        }()

        let confidenceLabel: String = {
            switch finalConfidence {
            case ..<0.40:
                return "Low confidence"
            case ..<0.70:
                return "Moderate confidence"
            default:
                return "High confidence"
            }
        }()

        return TestOutcome(
            leftEyeLogMAR: leftLogMAR,
            rightEyeLogMAR: rightLogMAR,
            leftEyePassed: leftFinalPass,
            rightEyePassed: rightFinalPass,
            overallPassed: overallPassed,
            isValid: isValid,
            confidence: finalConfidence,
            confidenceLabel: confidenceLabel,
            reliabilityLabel: finalReliability,
            notSureCount: notSureCount,
            totalResponseCount: totalResponses,
            maxConsecutiveNotSure: maxConsecutiveNotSureCount,
            resultMode: resultMode,
            interpretation: interpretation,
            startTime: start,
            endTime: end
        )
    }
    // MARK: - Confidence

    func computeConfidence(session: VisionTestSession) -> Double {
        let total = max(session.totalTrials, session.responses.count)
        let reversals = session.reversalCount

        if total == 0 {
            return notSureCount > 0 ? 0.10 : 0.0
        }

        let correctCount = session.responses.filter { $0.correct }.count
        let accuracy = Double(correctCount) / Double(total)
        let notSurePenalty = min(notSureRatio * 0.35, 0.35)

        if total < 8 {
            let early = min(0.35, accuracy)
            return max(0.10, early - notSurePenalty)
        }

        let reversalScore: Double
        switch reversals {
        case 0...1: reversalScore = 0.30
        case 2...3: reversalScore = 0.55
        case 4...5: reversalScore = 0.80
        default:    reversalScore = 0.90
        }

        let trialScore = min(Double(total) / 12.0, 1.0)
        let clamp = reversals < 4 ? 0.70 : 0.95

        let raw =
            (0.45 * accuracy) +
            (0.40 * reversalScore) +
            (0.15 * trialScore) -
            notSurePenalty

        return min(max(raw, 0.0), clamp)
    }

    // MARK: - Reliability

    var reliability: String {
        reliabilityLabel(for: nil)
    }

    private var notSureRatio: Double {
        Double(notSureCount) / Double(max(totalResponses, 1))
    }

    private func reliabilityLabel(for finalLogMAR: Double?) -> String {
        let ratio = notSureRatio

        if let finalLogMAR, ratio >= 0.40, finalLogMAR >= 0.80 {
            return "Low"
        }

        if ratio > 0.50 || maxConsecutiveNotSureCount >= 5 {
            return "Low"
        }

        if ratio > 0.30 || maxConsecutiveNotSureCount >= 3 {
            return "Moderate"
        }

        return "High"
    }

    private func resetReliabilityCounters() {
        notSureCount = 0
        totalResponses = 0
        consecutiveNotSureCount = 0
        maxConsecutiveNotSureCount = 0
    }

    private func updateNotSureTracking(wasNotSure: Bool) {
        if wasNotSure {
            notSureCount += 1
            consecutiveNotSureCount += 1
            maxConsecutiveNotSureCount = max(maxConsecutiveNotSureCount, consecutiveNotSureCount)
        } else {
            consecutiveNotSureCount = 0
        }
    }

    private func applyReliabilityGuardIfNeeded(session: VisionTestSession) {
        let ratio = notSureRatio

        guard session.totalTrials > 0 else { return }

        if session.currentLogMAR <= 0.0 && ratio > 0.30 {
            session.currentLogMAR = 0.20
            print("[RELIABILITY GUARD] Adjusted overly optimistic result to 0.20 due to high Not Sure ratio")
        }
    }

    // MARK: - Fallback Adaptive

    private func internalAdaptiveUpdate(session: VisionTestSession, correct: Bool) {
        let isLandolt = session.hasEnteredLandoltC

        let step = isLandolt ? 0.1 : session.stepSize
        let before = session.currentLogMAR
        let next = before + (correct ? -step : step)

        let lowerBound: Double = isLandolt ? 0.0 : -0.2
        let upperBound: Double = 1.2

        let clamped = max(lowerBound, min(upperBound, next))
        session.currentLogMAR = clamped

        print("""
        [STAIRCASE]
        before: \(before)
        step: \(step)
        correct: \(correct)
        isLandolt: \(isLandolt)
        next: \(next)
        lowerBound: \(lowerBound)
        clamped: \(clamped)
        """)
    }

    // MARK: - Symbol

    private func symbol(for direction: ResponseDirection, optotype: Stimulus.Optotype) -> String {
        if optotype == .landoltC {
            return "C"
        }

        switch direction {
        case .up: return "↑"
        case .down: return "↓"
        case .left: return "←"
        case .right: return "→"
        case .upLeft: return "↖"
        case .upRight: return "↗"
        case .downLeft: return "↙"
        case .downRight: return "↘"
        }
    }

    private func randomDirection() -> ResponseDirection {
        let all = ResponseDirection.allCases
        let filtered = all.filter { $0 != lastDirection }

        let chosen = filtered.randomElement() ?? .up
        lastDirection = chosen
        return chosen
    }
}
