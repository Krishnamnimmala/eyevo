import Foundation
import Combine
import os.log

@MainActor
final class VisionTestViewModel: ObservableObject {

    // Use the same persistent ID source as Welcome screen
    let eyevoID: String = EyevoIDStore.shared.eyevoID

    // MARK: - Engine & Session

    private let engine: VisionTestEngine
    private var session: VisionTestSession

    // MARK: - Logging

    private let log = Logger(
        subsystem: "com.yourcompany.eyevo",
        category: "VisionFlow"
    )

    // MARK: - Published UI State

    @Published var phase: TestPhase = .gatekeeper
    @Published private(set) var hasBegunTest: Bool = false

    @Published var currentStimulus: Stimulus?
    @Published var currentLogMAR: Double = 0.8

    @Published var showOptotype: Bool = false
    @Published var showButtons: Bool = false
    @Published var buttonsEnabled: Bool = false

    @Published var stepSize: Double?
    @Published var reversalCount: Int?

    // Reliability / Not Sure tracking
    @Published var notSureCount: Int = 0
    @Published var totalResponseCount: Int = 0
    @Published var reliabilityLabel: String = "High"

    // Enforcement trigger
    @Published var requiresEnforcement: Bool = false

    // MARK: - Timing

    /// Delay before showing response controls, while optotype remains visible
    private let responseRevealDelay: TimeInterval = 0.9

    /// Delay before enabling controls after they appear
    private let buttonEnableDelay: TimeInterval = 0.25

    /// Brief confirmation hold after user responds before advancing
    private let postResponseHold: TimeInterval = 0.30

    /// Small gap before starting next trial
    private let nextTrialDelay: TimeInterval = 0.08

    // MARK: - Initializers

    init(engine: VisionTestEngine) {
        self.engine = engine
        self.session = engine.startSession()
        syncFromSession()
        log.info("VisionTestViewModel initialized")
    }

    convenience init(algorithm: AdaptiveAlgorithm) {
        let engine = VisionTestEngine(algorithm: algorithm)
        self.init(engine: engine)
    }

    // MARK: - Public Flow Control

    func beginTest() {
        guard CalibrationStore.shared.pxPerMM != nil else {
            assertionFailure("Calibration missing — pxPerMM is nil")
            return
        }

        guard !hasBegunTest else { return }

        session.testStartTime = Date()

        hasBegunTest = true
        resetUIState()
        resetReliabilityState()
        syncFromSession()

        startTrialCycle()
    }

    func restartTest() {
        hasBegunTest = false
        resetUIState()
        resetReliabilityState()

        session = engine.startSession()
        syncFromSession()

        beginTest()
    }

    // MARK: - Enforcement Confirmation

    func confirmEnforcement() {
        session.didEnforceForCurrentEye = true
        requiresEnforcement = false

        log.debug("Enforcement confirmed")
        startTrialCycle()
    }

    // MARK: - Trial Cycle

    private func startTrialCycle() {
        guard session.phase != .completed else {
            phase = .completed
            return
        }

        if session.didEnforceForCurrentEye == false {
            resetUIState()
            requiresEnforcement = true
            return
        }

        requiresEnforcement = false

        let stimulus = engine.nextStimulus(session: session)

        syncFromSession()

        currentStimulus = stimulus
        showOptotype = true
        showButtons = false
        buttonsEnabled = false

        log.debug("TRIAL START → logMAR=\(stimulus.sizeLogMAR), px=\(stimulus.pixelSize)")

        DispatchQueue.main.asyncAfter(deadline: .now() + responseRevealDelay) { [weak self] in
            guard let self else { return }
            guard self.session.phase != .completed else { return }
            guard self.currentStimulus?.id == stimulus.id else { return }

            self.showOptotype = true
            self.showButtons = true

            DispatchQueue.main.asyncAfter(deadline: .now() + self.buttonEnableDelay) { [weak self] in
                guard let self else { return }
                guard self.session.phase != .completed else { return }
                guard self.currentStimulus?.id == stimulus.id else { return }

                self.buttonsEnabled = true
            }
        }
    }

    // MARK: - Response Handling

    func submitResponse(_ direction: ResponseDirection, rtMs: Int) {
        guard let stimulus = currentStimulus else { return }
        guard phase != .completed else { return }
        guard buttonsEnabled else { return }

        buttonsEnabled = false
        totalResponseCount += 1

        let correct = isResponseCorrect(
            response: direction,
            expected: stimulus.openingDirection,
            optotype: stimulus.optotype
        )

        engine.submitResponse(
            session: session,
            direction: direction,
            phase: stimulus.phase,
            correct: correct,
            rtMs: rtMs
        )

        updateReliability()
        syncFromSession()
        finalizeResponseTransition()
    }

    func submitNotSure(rtMs: Int) {
        guard let stimulus = currentStimulus else { return }
        guard phase != .completed else { return }
        guard buttonsEnabled else { return }

        buttonsEnabled = false
        notSureCount += 1
        totalResponseCount += 1

        // ✅ Correct routing — use dedicated Not Sure path
        engine.submitNotSure(
            session: session,
            phase: stimulus.phase,
            rtMs: rtMs
        )

        updateReliability()
        syncFromSession()
        finalizeResponseTransition()
    }

    private func isResponseCorrect(
        response: ResponseDirection,
        expected: ResponseDirection,
        optotype: Stimulus.Optotype
    ) -> Bool {
        switch optotype {
        case .landoltC:
            // Strict in Landolt-C mode
            return response == expected

        case .arrows:
            // User-friendly in arrow mode:
            // allow diagonal responses to map to the nearest cardinal direction.
            return normalizedDirection(response) == normalizedDirection(expected)
        }
    }

    private func normalizedDirection(_ direction: ResponseDirection) -> ResponseDirection {
        switch direction {
        case .up, .upLeft, .upRight:
            return .up
        case .down, .downLeft, .downRight:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        }
    }

    // MARK: - Results

    func produceFinalOutcome() -> TestOutcome {
        let leftPass = session.leftEyePassed
        let rightPass = session.rightEyePassed

        let rawOverallPassed: Bool = {
            guard let l = leftPass, let r = rightPass else { return false }
            return l && r
        }()

        let confidenceValue = session.confidence

        let confidenceLabel: String = {
            switch confidenceValue {
            case 0.75...1.0:
                return "High confidence"
            case 0.45..<0.75:
                return "Moderate confidence"
            default:
                return "Low confidence"
            }
        }()

        let reliability = reliabilityLabel

        let worstEyeLogMAR = max(
            session.leftEyeLogMAR ?? -99,
            session.rightEyeLogMAR ?? -99
        )

        let notSureRatio = Double(notSureCount) / Double(max(totalResponseCount, 1))

        let resultMode: ResultMode = {
            if notSureRatio >= 0.40 && worstEyeLogMAR >= 0.80 {
                return .floorEstimate
            } else {
                return .threshold
            }
        }()

        let interpretation: String = {
            if resultMode == .floorEstimate {
                return "Unable to reliably resolve optotypes. Significant blur may be present."
            }

            switch reliability.lowercased() {
            case "high":
                return "Stable threshold obtained."
            case "moderate":
                return "Reduced certainty due to inconsistent responses."
            default:
                return "Low-confidence result. Retest recommended."
            }
        }()

        let isValidFromConvergence =
            (session.totalTrials >= 15 && session.reversalCount >= 4) ||
            (session.totalTrials >= 20)

        let hasBothEyes = (leftPass != nil && rightPass != nil)

        // PASS should require stronger evidence than REFER
        let canIssuePass =
            reliability.lowercased() == "high" &&
            confidenceValue >= 0.70 &&
            notSureRatio < 0.15

        let overallPassed = rawOverallPassed && canIssuePass

        // A run can still be "valid" without being a PASS,
        // but low reliability should not look complete/strong.
        let isValid: Bool = {
            if resultMode == .floorEstimate {
                return true
            }

            if !hasBothEyes || !isValidFromConvergence {
                return false
            }

            if reliability.lowercased() == "low" {
                return false
            }

            return true
        }()

        let safeStart = session.testStartTime ?? Date()
        let safeEnd = session.testEndTime ?? Date()

        return TestOutcome(
            leftEyeLogMAR: session.leftEyeLogMAR,
            rightEyeLogMAR: session.rightEyeLogMAR,
            leftEyePassed: session.leftEyePassed,
            rightEyePassed: session.rightEyePassed,
            overallPassed: overallPassed,
            isValid: isValid,
            confidence: confidenceValue,
            confidenceLabel: confidenceLabel,
            reliabilityLabel: reliability,
            notSureCount: notSureCount,
            totalResponseCount: totalResponseCount,
            maxConsecutiveNotSure: engine.maxConsecutiveNotSureCount,
            resultMode: resultMode,
            interpretation: interpretation,
            startTime: safeStart,
            endTime: safeEnd
        )
    }

    // MARK: - Helpers

    private func finalizeResponseTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + postResponseHold) { [weak self] in
            guard let self else { return }

            self.resetUIState()

            guard self.session.phase != .completed else {
                self.phase = .completed
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.nextTrialDelay) { [weak self] in
                self?.startTrialCycle()
            }
        }
    }

    private func resetUIState() {
        currentStimulus = nil
        showOptotype = false
        showButtons = false
        buttonsEnabled = false
    }

    private func resetReliabilityState() {
        notSureCount = 0
        totalResponseCount = 0
        reliabilityLabel = "High"
    }

    private func updateReliability() {
        guard totalResponseCount > 0 else {
            reliabilityLabel = "High"
            return
        }

        let notSureRate = Double(notSureCount) / Double(totalResponseCount)

        if notSureRate > 0.35 {
            reliabilityLabel = "Low"
        } else if notSureRate > 0.20 {
            reliabilityLabel = "Moderate"
        } else {
            reliabilityLabel = "High"
        }
    }

    private func syncFromSession() {
        phase = session.phase
        currentLogMAR = session.currentLogMAR
        stepSize = session.stepSize
        reversalCount = session.reversalCount
    }

    var currentEye: Eye {
        session.currentEye
    }
}
