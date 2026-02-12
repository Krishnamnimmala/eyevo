//
//  EyevoCalibrationView.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/31/26.
//

import SwiftUI
import UIKit

struct CreditCardCalibrationView: View {

    let onComplete: () -> Void

    // ISO/IEC 7810 ID-1 credit card width
    private let cardWidthMM: Double = 85.60

    // UI state (POINTS, not pixels)
    @State private var overlayWidthPoints: CGFloat = 300
    @State private var confirmed = false

    // Derived calibrated value (PHYSICAL pixels/mm)
    private var calibratedPxPerMM: Double {
        CalibrationStore.shared.computePxPerMM(
            measuredWidthPoints: overlayWidthPoints,
            realCardWidthMM: cardWidthMM
        )
    }

    var body: some View {
        VStack(spacing: 28) {

            // Header
            VStack(spacing: 8) {
                Text("Screen Calibration")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Align a standard card with the rectangle below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Card Overlay Area
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        style: StrokeStyle(lineWidth: 3, dash: [8])
                    )
                    .frame(
                        width: overlayWidthPoints,
                        height: overlayWidthPoints * 0.63
                    )
                    .foregroundColor(.blue)

                Text("Align card here")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 20)

            // Adjustment Slider
            VStack(spacing: 6) {
                Slider(
                    value: $overlayWidthPoints,
                    in: 200...380,
                    step: 1
                )

                Text("Adjust until the card fits exactly")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Debug / transparency (can hide later)
            VStack(spacing: 4) {
                Text(
                    String(
                        format: "Calibrated px/mm: %.2f",
                        calibratedPxPerMM
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Confirm Button
            Button {
                CalibrationStore.shared.save(
                    pxPerMM: calibratedPxPerMM
                )
                confirmed = true
            } label: {
                Text("Confirm Calibration")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
        .alert("Calibration Saved", isPresented: $confirmed) {
            Button("OK") {
                onComplete()
            }
        } message: {
            Text("Your screen is now calibrated for accurate vision testing.")
        }
    }
}

