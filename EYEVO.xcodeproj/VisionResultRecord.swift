import Foundation

struct VisionResultRecord: Identifiable, Codable {

    let id: UUID
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval?

    let leftEyeLogMAR: Double?
    let rightEyeLogMAR: Double?

    let leftEyePassed: Bool?
    let rightEyePassed: Bool?

    let confidence: Double
    let overallPassed: Bool

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        duration: TimeInterval? = nil,
        leftEyeLogMAR: Double?,
        rightEyeLogMAR: Double?,
        leftEyePassed: Bool?,
        rightEyePassed: Bool?,
        confidence: Double,
        overallPassed: Bool
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.leftEyeLogMAR = leftEyeLogMAR
        self.rightEyeLogMAR = rightEyeLogMAR
        self.leftEyePassed = leftEyePassed
        self.rightEyePassed = rightEyePassed
        self.confidence = confidence
        self.overallPassed = overallPassed
    }
}
