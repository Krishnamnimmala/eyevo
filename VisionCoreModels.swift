
import Foundation

// MARK: - Test Phases

enum TestPhase {
    case gatekeeper
    case sloan10
    case completed
}

// MARK: - Response Direction

enum ResponseDirection: CaseIterable {
    case up
    case down
    case left
    case right
}

// MARK: - Optotype

enum Optotype {
    case sloan
}

//MARK: - DISTANCE Test parameter
    enum VisionTestDistanceMode: String, Codable {
    case near         // 35–45 cm (phone)
    case intermediate // ~70 cm (computer)
    case distance     // 2 m+ (room)
}

// MARK: - Test Outcome

struct TestOutcome {

    // Per-eye
    let leftEyeLogMAR: Double?
    let rightEyeLogMAR: Double?

    let leftEyePassed: Bool?
    let rightEyePassed: Bool?

    // Overall
    let overallPassed: Bool
    let isValid: Bool
    let confidence: Double

    // Timing
    let startTime: Date?
    let endTime: Date?
    let duration: TimeInterval?
}



// MARK: - Adaptive Algorithm Protocol


