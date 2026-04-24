import Foundation

struct VisionResultRecord: Identifiable, Codable {

    let id: UUID
    let eyevoID: String

    // Timing
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval?

    // Vision results
    let leftEyeLogMAR: Double?
    let rightEyeLogMAR: Double?

    let leftEyePassed: Bool?
    let rightEyePassed: Bool?

    // Outcome
    let confidence: Double
    let overallPassed: Bool

    // Reliability / Not Sure Tracking
    let notSureCount: Int
    let totalResponseCount: Int
    let reliabilityLabel: String

    enum CodingKeys: String, CodingKey {
        case id
        case eyevoID
        case startTime
        case endTime
        case duration
        case leftEyeLogMAR
        case rightEyeLogMAR
        case leftEyePassed
        case rightEyePassed
        case confidence
        case overallPassed
        case notSureCount
        case totalResponseCount
        case reliabilityLabel
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        eyevoID: String,
        startTime: Date,
        endTime: Date? = nil,
        duration: TimeInterval? = nil,
        leftEyeLogMAR: Double?,
        rightEyeLogMAR: Double?,
        leftEyePassed: Bool?,
        rightEyePassed: Bool?,
        confidence: Double,
        overallPassed: Bool,
        notSureCount: Int = 0,
        totalResponseCount: Int = 0,
        reliabilityLabel: String = "High"
    ) {
        self.id = id
        self.eyevoID = eyevoID
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.leftEyeLogMAR = leftEyeLogMAR
        self.rightEyeLogMAR = rightEyeLogMAR
        self.leftEyePassed = leftEyePassed
        self.rightEyePassed = rightEyePassed
        self.confidence = confidence
        self.overallPassed = overallPassed
        self.notSureCount = notSureCount
        self.totalResponseCount = totalResponseCount
        self.reliabilityLabel = reliabilityLabel
    }

    // MARK: - Backward-Compatible Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.eyevoID = try container.decodeIfPresent(String.self, forKey: .eyevoID) ?? "EYEVO-UNKNOWN"

        self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime) ?? Date()
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)

        self.leftEyeLogMAR = try container.decodeIfPresent(Double.self, forKey: .leftEyeLogMAR)
        self.rightEyeLogMAR = try container.decodeIfPresent(Double.self, forKey: .rightEyeLogMAR)

        self.leftEyePassed = try container.decodeIfPresent(Bool.self, forKey: .leftEyePassed)
        self.rightEyePassed = try container.decodeIfPresent(Bool.self, forKey: .rightEyePassed)

        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        self.overallPassed = try container.decodeIfPresent(Bool.self, forKey: .overallPassed) ?? false

        self.notSureCount = try container.decodeIfPresent(Int.self, forKey: .notSureCount) ?? 0
        self.totalResponseCount = try container.decodeIfPresent(Int.self, forKey: .totalResponseCount) ?? 0
        self.reliabilityLabel = try container.decodeIfPresent(String.self, forKey: .reliabilityLabel) ?? "High"
    }
}
