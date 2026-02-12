import Foundation

final class VisionTestSession {

    var hasEnteredLandoltC: Bool = false
    
    // MARK: - Phase
    var phase: TestPhase = .gatekeeper
    
    var pxPerMM: Double?

    // MARK: - Threshold state
    var currentLogMAR: Double = 0.8
    var stepSize: Double = 0.20

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
        phase = .completed
    }
}
