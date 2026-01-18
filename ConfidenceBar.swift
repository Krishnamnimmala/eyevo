//
//  ConfidenceBar.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/15/26.
//

import SwiftUI

struct ConfidenceBar: View {

    let confidence: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Confidence")
                .font(.headline)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))

                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(confidence ?? 0))
                }
            }
            .frame(height: 10)

            Text(confidenceLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var confidenceLabel: String {
        guard let confidence else { return "—" }
        return "\(Int(confidence * 100))%"
    }
}
