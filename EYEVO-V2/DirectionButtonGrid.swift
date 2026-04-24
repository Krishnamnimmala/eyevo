//
//  DirectionButtonGrid.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/24/26.
//

import SwiftUI

struct DirectionButtonGrid: View {

    let enabled: Bool
    let onSelect: (ResponseDirection) -> Void

    var body: some View {
        VStack(spacing: 18) {

            Button("↑") { onSelect(.up) }
                .buttonStyle(.borderedProminent)
                .disabled(!enabled)

            HStack(spacing: 18) {
                Button("←") { onSelect(.left) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!enabled)

                Button("→") { onSelect(.right) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!enabled)
            }

            Button("↓") { onSelect(.down) }
                .buttonStyle(.borderedProminent)
                .disabled(!enabled)
        }
    }
}
