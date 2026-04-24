import Foundation

final class VisionTestSession {


    var hasEnteredLandoltC: Bool = false
    
    // MARK: - Phase
    var phase: TestPhase = .gatekeeper
    
    var pxPerMM: Double?
    
    // MARK: - Per Eye Results
    var leftEyeLogMAR: Double?
    var rightEyeLogMAR: Double?
    
    var leftEyePassed: Bool?
    var rightEyePassed: Bool?
    
    // MARK: - Threshold state
    var currentLogMAR: Double = 0.8
    var stepSize: Double = 0.20
    
    // 👁 Eye control
    var currentEye: Eye = .left
    var didEnforceForCurrentEye: Bool = false
    var isTestingSecondEye: Bool = false

    // MARK: - Timing

    var testStartTime: Date?
    var testEndTime: Date?

    var testDuration: TimeInterval? {
        guard let start = testStartTime,
              let end = testEndTime else { return nil }
        return end.timeIntervalSince(start)
    }

    // MARK: - Modes

    var optotypeMode: OptotypeMode = .arrows   // 🔥 Arrow-only default
    var distanceMode: TestDistanceMode = .near

    // MARK: - Trial accounting
    var trials: Int = 0
    var totalTrials: Int = 0
    var trialsInPhase: Int = 0
    var correctInPhase: Int = 0
    var correctStreak: Int = 0
    var incorrectStreak: Int = 0

    /// -1 = harder, +1 = easier
    var lastStepDirection: Int? = nil


    // MARK: - Staircase convergence
    var reversalCount: Int = 0
    var reversalLogMARs: [Double] = []

    // MARK: - Confidence
    var confidence: Double = 1.0

    // MARK: - Responses (optional telemetry)
    var responses: [(correct: Bool, rtMs: Int)] = []

    // MARK: - Helpers
    func resetPhaseCounters() {
        trialsInPhase = 0
        correctInPhase = 0
        reversalCount = 0
        reversalLogMARs.removeAll()
    }

    func complete() {
        testEndTime = Date()
        phase = .completed
    }

}
