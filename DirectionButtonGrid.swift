//
//  DirectionButtonGrid.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/13/26.
//

import SwiftUI

struct DirectionButtonGrid: View {

    let enabled: Bool
    let onSelect: (Direction) -> Void

    var body: some View {
        VStack(spacing: 16) {

            Button(action: { onSelect(.up) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
            }
            .disabled(!enabled)

            HStack(spacing: 32) {
                Button(action: { onSelect(.left) }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(!enabled)

                Button(action: { onSelect(.right) }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(!enabled)
            }

            Button(action: { onSelect(.down) }) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.largeTitle)
            }
            .disabled(!enabled)
        }
        .foregroundColor(enabled ? .blue : .gray)
    }
}
