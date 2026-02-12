//
//  LandoltCShape.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/28/26.
//

import SwiftUI

/// Draws a Landolt C using a stroked ring with a gap
struct LandoltCShape: Shape {

    /// Fraction of circumference removed for the gap
    let gapRatio: CGFloat   // typically 0.2 (20%)

    func path(in rect: CGRect) -> Path {

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let startAngle = Angle.degrees(360 * gapRatio / 2)
        let endAngle   = Angle.degrees(360 - (360 * gapRatio / 2))

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}
