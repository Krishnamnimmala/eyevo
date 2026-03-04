import Foundation
import Combine
import os.log

@MainActor
final class VisionTestViewModel: ObservableObject {

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

    // Enforcement trigger
    @Published var requiresEnforcement: Bool = false

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
            fatalError("❌ Calibration missing — pxPerMM is nil")
        }

        guard !hasBegunTest else { return }

        // Start time (local)
        session.testStartTime = Date()

        hasBegunTest = true
        resetUIState()
        syncFromSession()

        startTrialCycle()
    }

    func restartTest() {
        hasBegunTest = false
        resetUIState()

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

    private func startTrialCycle(
        exposure: TimeInterval = 1.0,
        buttonEnableDelay: TimeInterval = 0.4
    ) {
        // Stop if completed
        guard session.phase != .completed else {
            phase = .completed
            return
        }

        // Enforcement gate (per-eye)
        if session.didEnforceForCurrentEye == false {
            requiresEnforcement = true
            return
        }

        // Generate stimulus
        let stimulus = engine.nextStimulus(session: session)

        syncFromSession()

        currentStimulus = stimulus
        showOptotype = true
        showButtons = false
        buttonsEnabled = false

        log.debug("TRIAL START → logMAR=\(stimulus.sizeLogMAR), px=\(stimulus.pixelSize)")

        DispatchQueue.main.asyncAfter(deadline: .now() + exposure) { [weak self] in
            guard let self else { return }
            guard self.session.phase != .completed else { return }

            self.showOptotype = false
            self.showButtons = true

            DispatchQueue.main.asyncAfter(deadline: .now() + buttonEnableDelay) { [weak self] in
                guard let self else { return }
                self.buttonsEnabled = true
            }
        }
    }

    // MARK: - Response Handling

    func submitResponse(_ direction: ResponseDirection, rtMs: Int) {
        guard let stimulus = currentStimulus else { return }

        let correct = (direction == stimulus.openingDirection)

        engine.submitResponse(
            session: session,
            direction: direction,
            phase: stimulus.phase,
            correct: correct,
            rtMs: rtMs
        )

        resetUIState()
        syncFromSession()

        // If completed, stop
        guard session.phase != .completed else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.startTrialCycle()
        }
    }

    // MARK: - Results (Single Source of Truth)

    func produceFinalOutcome() -> TestOutcome {

        // Determine validity from your convergence rules
        let total = session.totalTrials
        let reversals = session.reversalCount

        let isValidFromConvergence =
            (total >= 15 && reversals >= 4) ||
            (total >= 20)

        // IMPORTANT: Per-eye results MUST exist.
        // If either is nil, we mark invalid and overallPassed false.
        let leftPass = session.leftEyePassed
        let rightPass = session.rightEyePassed

        let hasBothEyes = (leftPass != nil && rightPass != nil)

        let overallPassed: Bool = {
            guard let l = leftPass, let r = rightPass else { return false }
            return l && r
        }()

        let isValid = isValidFromConvergence && hasBothEyes

        print("LEFT PASS:", leftPass as Any)
        print("RIGHT PASS:", rightPass as Any)
        print("OVERALL:", overallPassed, "VALID:", isValid)

        return TestOutcome(
            leftEyeLogMAR: session.leftEyeLogMAR,
            rightEyeLogMAR: session.rightEyeLogMAR,

            leftEyePassed: leftPass,
            rightEyePassed: rightPass,
            overallPassed: overallPassed,

            isValid: isValid,
            confidence: session.confidence,

            startTime: session.testStartTime,
            endTime: session.testEndTime,
            duration: session.testDuration
        )
    }

    // MARK: - Helpers

    private func resetUIState() {
        currentStimulus = nil
        showOptotype = false
        showButtons = false
        buttonsEnabled = false
    }

    private func syncFromSession() {
        phase = session.phase
        currentLogMAR = session.currentLogMAR
        stepSize = session.stepSize
        reversalCount = session.reversalCount
    }

    // Expose current eye to View
    var currentEye: Eye {
        session.currentEye
    }
}
