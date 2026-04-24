import Foundation

// MARK: - Test Phase

enum TestPhase: Codable {
    case gatekeeper
    case running
    case completed
}

// MARK: - Response Direction

enum ResponseDirection: CaseIterable, Codable {
    case up
    case down
    case left
    case right

    // Diagonal support
    case upLeft
    case upRight
    case downLeft
    case downRight
    
}
extension ResponseDirection {
    var cardinalEquivalent: ResponseDirection {
        switch self {
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
}
// MARK: - Result Mode

enum ResultMode: String, Codable {
    case threshold
    case floorEstimate
}

// MARK: - Test Outcome

struct TestOutcome: Codable {
    let leftEyeLogMAR: Double?
    let rightEyeLogMAR: Double?

    let leftEyePassed: Bool?
    let rightEyePassed: Bool?

    let overallPassed: Bool
    let isValid: Bool

    let confidence: Double
    let confidenceLabel: String
    let reliabilityLabel: String

    let notSureCount: Int
    let totalResponseCount: Int
    let maxConsecutiveNotSure: Int

    let resultMode: ResultMode
    let interpretation: String

    let startTime: Date
    let endTime: Date

    var durationSeconds: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var resultTitle: String {
        if overallPassed { return "PASS" }

        if !overallPassed && (leftEyePassed == true || rightEyePassed == true) {
            return "REFER"
        }

        return isValid ? "REFER" : "RETEST"
    }

    var disclaimerText: String {
        "EYEVO is a screening tool and does not replace a professional eye examination."
    }
}
