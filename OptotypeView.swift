//
//  OptotypeView.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/15/26.
//

import SwiftUI

struct OptotypeView: View {

    let optotype: Optotype
    let direction: ResponseDirection

    var body: some View {
        ZStack {
            Color.clear

            if case .tumblingE = optotype {
                TumblingEView()
                    .foregroundColor(.white)
                    .rotationEffect(rotationAngle)
            } else {
                // Fallback: show simple placeholder letter (shouldn't be used yet)
                Text("?")
                    .font(.system(size: 120, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }

    private var rotationAngle: Angle {
        switch direction {
        case .up: return .degrees(0)
        case .right: return .degrees(90)
        case .down: return .degrees(180)
        case .left: return .degrees(270)
        }
    }
}

/// Programmatic tumbling "E" constructed from rectangles. Scales to available size.
private struct TumblingEView: View {
    var body: some View {
        GeometryReader { g in
            let w = min(g.size.width, g.size.height)
            let h = w
            let thickness = w * 0.18
            let barLength = w * 0.6
            let leftX: CGFloat = (w - (thickness + barLength)) / 2.0

            ZStack {
                // Vertical stem
                Rectangle()
                    .frame(width: thickness, height: h * 0.9)
                    .position(x: leftX + thickness / 2.0, y: h / 2.0)

                // Top bar
                Rectangle()
                    .frame(width: barLength, height: thickness)
                    .position(x: leftX + thickness + barLength / 2.0, y: h * 0.18)

                // Middle bar
                Rectangle()
                    .frame(width: barLength, height: thickness)
                    .position(x: leftX + thickness + barLength / 2.0, y: h / 2.0)

                // Bottom bar
                Rectangle()
                    .frame(width: barLength, height: thickness)
                    .position(x: leftX + thickness + barLength / 2.0, y: h * 0.82)
            }
            .frame(width: w, height: h)
        }
    }
}
