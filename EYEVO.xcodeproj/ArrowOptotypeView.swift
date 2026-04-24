//
//  ArrowOptotypeView.swift
//  EYEVO
//
//  Arrow-based optotype with acuity-aware degradation.
//  As logMAR decreases (harder), orientation cues are intentionally reduced
//  to prevent blur-resistant guessing.
//
//  This design improves screening fidelity compared to static arrows.
//
//  Created by Krishnam Nimmala on 1/26/26.
//

import SwiftUI

struct ArrowOptotypeView: View {

    // MARK: - Inputs
    let direction: ResponseDirection
    let size: CGFloat
    let logMAR: Double

    // MARK: - View

    var body: some View {
        ArrowShape(
            shaftRatio: shaftRatio,
            headRatio: headRatio
        )
        .stroke(Color.white, lineWidth: strokeWidth)
        .frame(width: size, height: size)
        .rotationEffect(rotation)
        .accessibilityHidden(true) // prevent VoiceOver cueing
    }

    // MARK: - Acuity-Aware Degradation

    /// Shaft length relative to frame
    /// Shortens as acuity demand increases
    private var shaftRatio: CGFloat {
        switch logMAR {
        case ..<0.0:
            return 0.35   // very hard: minimal shaft
        case 0.0..<0.2:
            return 0.45
        default:
            return 0.65   // easy: full arrow
        }
    }

    /// Arrowhead size relative to frame
    /// Reduces orientation salience at small sizes
    private var headRatio: CGFloat {
        switch logMAR {
        case ..<0.0:
            return 0.20   // very small head
        case 0.0..<0.2:
            return 0.30
        default:
            return 0.45
        }
    }

    /// Stroke width scales with size but never collapses
    private var strokeWidth: CGFloat {
        max(1.5, size * 0.06)
    }

    // MARK: - Rotation

    private var rotation: Angle {
        switch direction {
        case .up:    return .degrees(0)
        case .right: return .degrees(90)
        case .down:  return .degrees(180)
        case .left:  return .degrees(270)
        }
    }
}

// MARK: - ArrowShape (Geometry-Based Optotype)

/// A simple geometric arrow shape whose proportions can be degraded.
/// Geometry (not symbols) is used to ensure blur sensitivity.
struct ArrowShape: Shape {

    /// Portion of height used by the shaft (0–1)
    let shaftRatio: CGFloat

    /// Portion of height used by the head (0–1)
    let headRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        let shaftHeight = h * shaftRatio
        let headHeight = h * headRatio
        let shaftWidth = w * 0.18

        let centerX = rect.midX
        let shaftTopY = rect.midY - shaftHeight / 2
        let shaftBottomY = rect.midY + shaftHeight / 2

        // Shaft
        path.addRect(
            CGRect(
                x: centerX - shaftWidth / 2,
                y: shaftTopY,
                width: shaftWidth,
                height: shaftHeight
            )
        )

        // Arrow head
        path.move(to: CGPoint(x: centerX, y: shaftTopY - headHeight))
        path.addLine(to: CGPoint(x: centerX - headHeight, y: shaftTopY))
        path.addLine(to: CGPoint(x: centerX + headHeight, y: shaftTopY))
        path.closeSubpath()

        return path
    }
}

