import Foundation
import Combine
import os.log

@MainActor
final class VisionTestViewModel: ObservableObject {

    // MARK: - Engine & Session (Single Source of Truth)

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

    /// Starts the test once calibration is confirmed
    func beginTest() {
        guard CalibrationStore.shared.pxPerMM != nil else {
            fatalError("❌ Calibration missing — pxPerMM is nil")
        }

        guard !hasBegunTest else { return }

        hasBegunTest = true
        resetUIState()
        syncFromSession()
        startTrialCycle()
    }

    /// Restarts with a fresh session (Retake flow)
    func restartTest() {
        hasBegunTest = false
        resetUIState()
        session = engine.startSession()
        syncFromSession()
        beginTest()
    }

    // MARK: - Trial Cycle

    private func startTrialCycle(
        exposure: TimeInterval = 1.0,
        buttonEnableDelay: TimeInterval = 0.4
    ) {
        guard session.phase != .completed else {
            phase = .completed
            return
        }

        // Generate next stimulus (engine owns size + difficulty)
        let stimulus = engine.nextStimulus(session: session)

        syncFromSession()

        currentStimulus = stimulus
        showOptotype = true
        showButtons = false
        buttonsEnabled = false

        log.debug("TRIAL START → logMAR=\(stimulus.sizeLogMAR), px=\(stimulus.pixelSize)")

        DispatchQueue.main.asyncAfter(deadline: .now() + exposure) {
            guard self.session.phase != .completed else { return }

            self.showOptotype = false
            self.showButtons = true

            DispatchQueue.main.asyncAfter(deadline: .now() + buttonEnableDelay) {
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

        guard session.phase != .completed else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.startTrialCycle()
        }
    }

    // MARK: - Results

    func produceFinalOutcome() -> TestOutcome {

        let total = session.totalTrials
        let reversals = session.reversalCount

        let isValid =
            (total >= 15 && reversals >= 4) ||
            (total >= 20)

        let estimatedLogMAR: Double = {
            if session.reversalLogMARs.count >= 2 {
                let tail = session.reversalLogMARs.suffix(4)
                return tail.reduce(0.0, +) / Double(tail.count)
            } else {
                return session.currentLogMAR
            }
        }()

        let passed = isValid && estimatedLogMAR <= 0.3

        return TestOutcome(
            estimatedLogMAR: isValid ? estimatedLogMAR : nil,
            confidence: session.confidence,
            isValid: isValid,
            passed: passed
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
}
