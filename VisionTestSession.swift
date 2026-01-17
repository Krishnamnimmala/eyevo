import Foundation

/// Holds all mutable state for a single vision screening run.
/// This object is owned by the ViewModel and passed into VisionTestEngine.
/// It contains NO UI logic and NO timing logic.

final class VisionTestSession {
    
    // MARK: - Progress Tracking
    var trials: Int = 0
    
    
    
    // MARK: - Phase Tracking
    
    /// Current phase of the test
    var phase: TestPhase = .gatekeeper
    
    /// Whether the session has completed
    var isCompleted: Bool = false
    
    // MARK: - Trial Counters
    
    /// Total number of trials in the current phase
    var trialsInPhase: Int = 0
    
    /// Total number of correct responses in the current phase
    var correctInPhase: Int = 0
    
    /// Total number of trials across the whole session
    var totalTrials: Int = 0
    
    // MARK: - Adaptive State (QUEST / Staircase)
    
    /// Current logMAR size being tested
    var currentLogMAR: Double = 0.8   // start large (easy)
    
    /// Step size for staircase / QUEST updates
    var stepSize: Double = 0.1
    
    /// Direction of last size update (-1 smaller, +1 larger)
    var lastDirection: Int = 0
    
    /// Number of reversals detected in the current phase
    var reversalCount: Int = 0
    
    // MARK: - Response History
    
    /// Stores (correct, responseTimeMs) for all trials
    var responses: [(correct: Bool, rtMs: Int)] = []
    
    // MARK: - Confidence & Validity
    
    /// Confidence score [0.0 – 1.0]
    var confidence: Double = 1.0
    
    /// Whether the Tumbling E phase qualifies for Sloan letters
    var sloanEligible: Bool = false
    
    // MARK: - Results Storage
    
    /// Final estimated acuity from Tumbling E (if completed)
    var tumblingEResultLogMAR: Double?
    
    /// Final estimated acuity from Sloan Letters (if completed)
    var sloanResultLogMAR: Double?
    
    // MARK: - Lifecycle
    
    init() {}
    
    /// Reset per-phase counters when switching phases
    func resetPhaseCounters() {
        trialsInPhase = 0
        correctInPhase = 0
        reversalCount = 0
        lastDirection = 0
        responses.removeAll()
    }
    
    /// Mark the session as finished
    func complete() {
        isCompleted = true
        phase = .completed
    }
    
}
