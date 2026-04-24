import Foundation
import CoreGraphics

struct Stimulus: Identifiable {

    let id = UUID()          // ✅ ADD THIS

    let phase: TestPhase
    let optotype: Optotype
    let openingDirection: ResponseDirection
    let symbol: String
    let sizeLogMAR: Double
    let pixelSize: CGFloat

    enum Optotype {
        case arrows
        case landoltC
    }
}
