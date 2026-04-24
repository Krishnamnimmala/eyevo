import Foundation

struct ThresholdConfirmationState {

    var isActive: Bool = false
    var targetLogMAR: Double = 0.0

    var requiredTrials: Int = 3
    var completedTrials: Int = 0
    var correctTrials: Int = 0

    mutating func start(targetLogMAR: Double, requiredTrials: Int = 3) {
        self.isActive = true
        self.targetLogMAR = targetLogMAR
        self.requiredTrials = requiredTrials
        self.completedTrials = 0
        self.correctTrials = 0
    }

    mutating func reset() {
        isActive = false
        targetLogMAR = 0.0
        requiredTrials = 3
        completedTrials = 0
        correctTrials = 0
    }

    mutating func record(correct: Bool) {
        completedTrials += 1
        if correct {
            correctTrials += 1
        }
    }

    var isSatisfied: Bool {
        completedTrials >= requiredTrials && correctTrials >= 2
    }

    var isFailed: Bool {
        completedTrials >= requiredTrials && correctTrials < 2
    }
}

final class VisionTestSession {

    // MARK: - Core Progress / Phase

    var phase: TestPhase = .gatekeeper
    var pxPerMM: Double?

    // MARK: - Per-Eye Results

    var leftEyeLogMAR: Double?
    var rightEyeLogMAR: Double?

    var leftEyePassed: Bool?
    var rightEyePassed: Bool?

    // MARK: - Threshold / Adaptive State

    var currentLogMAR: Double = 0.8
    var stepSize: Double = 0.20
    var hasEnteredLandoltC: Bool = false
    var thresholdConfirmation = ThresholdConfirmationState()

    // MARK: - Eye Control

    var currentEye: Eye = .left
    var didEnforceForCurrentEye: Bool = false
    var isTestingSecondEye: Bool = false

    // MARK: - Timing

    var testStartTime: Date?
    var testEndTime: Date?

    var testDuration: TimeInterval? {
        guard let start = testStartTime, let end = testEndTime else { return nil }
        return end.timeIntervalSince(start)
    }

    // MARK: - Test Modes

    var optotypeMode: OptotypeMode = .arrows
    var distanceMode: TestDistanceMode = .near

    // MARK: - Trial Accounting

    var trials: Int = 0
    var totalTrials: Int = 0
    var trialsInPhase: Int = 0
    var correctInPhase: Int = 0

    var correctStreak: Int = 0
    var incorrectStreak: Int = 0

    /// -1 = harder, +1 = easier
    var lastStepDirection: Int?

    // MARK: - Staircase / Convergence

    var reversalCount: Int = 0
    var reversalLogMARs: [Double] = []

    // MARK: - Confidence / Telemetry

    var confidence: Double = 1.0
    var responses: [(correct: Bool, rtMs: Int)] = []

    // MARK: - Lifecycle

    init() { }

    // MARK: - Helpers

    func resetPhaseCounters() {
        trialsInPhase = 0
        correctInPhase = 0
        correctStreak = 0
        incorrectStreak = 0
        lastStepDirection = nil
        reversalCount = 0
        reversalLogMARs = []
        responses = []
        thresholdConfirmation.reset()
    }

    func resetForNextEye() {
        currentLogMAR = 0.8
        stepSize = 0.20
        hasEnteredLandoltC = false

        trials = 0
        totalTrials = 0
        trialsInPhase = 0
        correctInPhase = 0

        correctStreak = 0
        incorrectStreak = 0
        lastStepDirection = nil

        reversalCount = 0
        reversalLogMARs = []
        responses = []

        didEnforceForCurrentEye = false
        thresholdConfirmation.reset()
    }

    func beginIfNeeded() {
        if testStartTime == nil {
            testStartTime = Date()
        }
    }

    func complete() {
        testEndTime = Date()
        phase = .completed
    }
}
