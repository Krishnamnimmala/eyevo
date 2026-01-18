//
//  DirectionButtonGrid.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/13/26.
//

import SwiftUI

struct DirectionButtonGrid: View {

    let enabled: Bool
    let onSelect: (ResponseDirection) -> Void

    var body: some View {
        VStack(spacing: 16) {

            Button(action: { onSelect(.up) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
            }
            .disabled(!enabled)
            .accessibilityLabel("Up")
            .accessibilityIdentifier("direction.up")

            HStack(spacing: 32) {
                Button(action: { onSelect(.left) }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(!enabled)
                .accessibilityLabel("Left")
                .accessibilityIdentifier("direction.left")

                Button(action: { onSelect(.right) }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(!enabled)
                .accessibilityLabel("Right")
                .accessibilityIdentifier("direction.right")
            }

            Button(action: { onSelect(.down) }) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.largeTitle)
            }
            .disabled(!enabled)
            .accessibilityLabel("Down")
            .accessibilityIdentifier("direction.down")
        }
        .foregroundColor(enabled ? .blue : .gray)
    }
}
