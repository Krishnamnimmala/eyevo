import SwiftUI

/// Harder / less obvious Landolt-C rendering for mobile screening.
/// This version uses a wedge-cut gap rather than a clean arc-only opening,
/// which makes the gap slightly more ambiguous and less easy to detect at a glance.
struct LandoltCShape: Shape {

    let openingDirection: ResponseDirection
    let gapAngle: Double
    let ringThicknessRatio: CGFloat

    init(
        openingDirection: ResponseDirection,
        gapAngle: Double = 20,
        ringThicknessRatio: CGFloat = 0.22
    ) {
        self.openingDirection = openingDirection
        self.gapAngle = gapAngle
        self.ringThicknessRatio = ringThicknessRatio
    }

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let outerRadius = side / 2.0
        let ringThickness = max(1.5, side * ringThicknessRatio)
        let innerRadius = max(0.0, outerRadius - ringThickness)

        let startDeg = openingCenterDegrees - (gapAngle / 2.0)
        let endDeg = openingCenterDegrees + (gapAngle / 2.0)

        var ring = Path()

        // Outer circle
        ring.addEllipse(in: CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2.0,
            height: outerRadius * 2.0
        ))

        // Inner cutout
        ring.addEllipse(in: CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2.0,
            height: innerRadius * 2.0
        ))

        // Wedge-cut gap — slightly more ambiguous than a clean arc gap
        var gap = Path()
        gap.move(to: center)
        gap.addLine(to: point(on: center, radius: outerRadius + 2.0, degrees: startDeg))
        gap.addArc(
            center: center,
            radius: outerRadius + 2.0,
            startAngle: .degrees(startDeg),
            endAngle: .degrees(endDeg),
            clockwise: false
        )
        gap.addLine(to: center)
        gap.closeSubpath()

        ring.addPath(gap)
        return ring
    }

    private var openingCenterDegrees: Double {
        switch openingDirection {
        case .right:     return 0
        case .downRight: return 45
        case .down:      return 90
        case .downLeft:  return 135
        case .left:      return 180
        case .upLeft:    return 225
        case .up:        return 270
        case .upRight:   return 315
        }
    }

    private func point(on center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180.0
        return CGPoint(
            x: center.x + CGFloat(cos(radians)) * radius,
            y: center.y + CGFloat(sin(radians)) * radius
        )
    }
}
