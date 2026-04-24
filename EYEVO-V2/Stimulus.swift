import Foundation
import CoreGraphics

struct Stimulus: Identifiable, Equatable {

    // MARK: - Identity

    let id: UUID = UUID()

    // MARK: - Core Properties

    let phase: TestPhase
    let optotype: Optotype
    let openingDirection: ResponseDirection
    let symbol: String
    let sizeLogMAR: Double
    let pixelSize: CGFloat

    // MARK: - Optotype Type

    enum Optotype {
        case arrows
        case landoltC
    }

    // MARK: - Convenience

    var isLandolt: Bool {
        optotype == .landoltC
    }

    var isArrow: Bool {
        optotype == .arrows
    }
}
