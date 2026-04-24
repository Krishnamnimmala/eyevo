//
//  DirectionalInputPad.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 4/5/26.
//

import SwiftUI
import Foundation

enum DirectionalPadDirection: CaseIterable, Hashable {
    case up
    case upRight
    case right
    case downRight
    case down
    case downLeft
    case left
    case upLeft

    var accessibilityLabel: String {
        switch self {
        case .up: return "Up"
        case .upRight: return "Up Right"
        case .right: return "Right"
        case .downRight: return "Down Right"
        case .down: return "Down"
        case .downLeft: return "Down Left"
        case .left: return "Left"
        case .upLeft: return "Up Left"
        }
    }

    var systemImageName: String {
        switch self {
        case .up: return "arrow.up"
        case .upRight: return "arrow.up.right"
        case .right: return "arrow.right"
        case .downRight: return "arrow.down.right"
        case .down: return "arrow.down"
        case .downLeft: return "arrow.down.left"
        case .left: return "arrow.left"
        case .upLeft: return "arrow.up.left"
        }
    }

    /// 0 degrees = right, -90 = up
    var angleDegrees: Double {
        switch self {
        case .up: return -90
        case .upRight: return -45
        case .right: return 0
        case .downRight: return 45
        case .down: return 90
        case .downLeft: return 135
        case .left: return 180
        case .upLeft: return 225
        }
    }

    static let radialOrder: [DirectionalPadDirection] = [
        .up, .upRight, .right, .downRight, .down, .downLeft, .left, .upLeft
    ]
}

struct DirectionalInputPad: View {
    let onSelect: (DirectionalPadDirection) -> Void
    var isEnabled: Bool = true

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)

            let outerPadding: CGFloat = isCompactWidth ? 8 : 12
            let wheelSize = max(200, side - outerPadding * 2)

            let buttonSize: CGFloat = isCompactWidth
                ? min(max(wheelSize * 0.24, 64), 82)
                : min(max(wheelSize * 0.22, 68), 90)

            let hubSize: CGFloat = isCompactWidth ? 56 : 64
            let orbitRadius: CGFloat = max(62, (wheelSize / 2) - (buttonSize / 2) - 10)
            let arrowFontSize: CGFloat = max(24, buttonSize * 0.40)

            ZStack {
                outerRing(size: wheelSize)
                innerRing(size: wheelSize * 0.62)

                spoke(angle: 0, radius: orbitRadius)
                spoke(angle: 45, radius: orbitRadius)
                spoke(angle: 90, radius: orbitRadius)
                spoke(angle: 135, radius: orbitRadius)

                centerHub(size: hubSize)

                ForEach(DirectionalPadDirection.radialOrder, id: \.self) { direction in
                    radialButton(
                        direction,
                        buttonSize: buttonSize,
                        arrowFontSize: arrowFontSize,
                        orbitRadius: orbitRadius
                    )
                }
            }
            .frame(width: wheelSize, height: wheelSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(outerPadding)
        }
        .frame(minHeight: 230)
    }

    @ViewBuilder
    private func outerRing(size: CGFloat) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.14),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func innerRing(size: CGFloat) -> some View {
        Circle()
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func centerHub(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.07),
                            Color.white.opacity(0.02)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: size / 2
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)

            Image(systemName: "scope")
                .font(.system(size: size * 0.28, weight: .medium))
                .foregroundColor(.white.opacity(0.30))
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func radialButton(
        _ direction: DirectionalPadDirection,
        buttonSize: CGFloat,
        arrowFontSize: CGFloat,
        orbitRadius: CGFloat
    ) -> some View {
        Button {
            guard isEnabled else { return }
            onSelect(direction)
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray6),
                                Color(.systemGray5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isEnabled
                                    ? [Color.blue.opacity(0.95), Color.blue.opacity(0.70)]
                                    : [Color.gray.opacity(0.55), Color.gray.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: Color.blue.opacity(isEnabled ? 0.18 : 0.0), radius: 5, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)

                Image(systemName: direction.systemImageName)
                    .font(.system(size: arrowFontSize, weight: .bold))
                    .foregroundColor(isEnabled ? .blue : .gray)
            }
            .frame(width: buttonSize, height: buttonSize)
            .contentShape(Circle())
            .opacity(isEnabled ? 1.0 : 0.55)
            .scaleEffect(isEnabled ? 1.0 : 0.98)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(direction.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .offset(position(for: direction, radius: orbitRadius))
    }

    private func position(for direction: DirectionalPadDirection, radius: CGFloat) -> CGSize {
        let radians = direction.angleDegrees * .pi / 180

        return CGSize(
            width: CGFloat(Foundation.cos(radians)) * radius,
            height: CGFloat(Foundation.sin(radians)) * radius
        )
    }

    @ViewBuilder
    private func spoke(angle: Double, radius: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.045))
            .frame(width: 1, height: radius * 2)
            .rotationEffect(.degrees(angle))
    }
}

#Preview("Premium Radial Pad") {
    ZStack {
        Color.black.ignoresSafeArea()

        DirectionalInputPad { direction in
            print(direction)
        }
        .padding(.horizontal, 16)
        .frame(height: 300)
    }
}
