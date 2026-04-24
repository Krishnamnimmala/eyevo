import SwiftUI

struct EyevoCalibrationView: View {

    let onCalibrationComplete: () -> Void

    @State private var cardWidthPoints: CGFloat = 260
    @State private var errorMessage: String?
    @State private var isValidMeasurement: Bool = false
    @State private var showSelfCheck = false

    private let eyevoBlue = Color(red: 0.00, green: 0.48, blue: 1.00)
    private let minWidth: CGFloat = 160
    private let maxWidthMultiplier: CGFloat = 0.95
    private let fineStep: CGFloat = 0.5

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * maxWidthMultiplier
    }
    

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: Header
                    VStack(spacing: 10) {
                        Text("Screen Calibration")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Quick setup for accurate vision screening")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // MARK: Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to set up")
                            .font(.headline)

                        InstructionRow(number: "1", text: "Hold your phone upright")
                        InstructionRow(number: "2", text: "Use any standard ID-sized card")
                        InstructionRow(number: "3", text: "Place it flat on the screen horizontally")
                        InstructionRow(number: "4", text: "Adjust until the blue outline matches the outer edges")

                        Text("Examples: driver’s license, badge, or payment card")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("EYEVO does not scan or read any card information.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // MARK: Card Preview
                    VStack(spacing: 16) {
                        Text("Place card here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isValidMeasurement ? Color.green : eyevoBlue,
                                    lineWidth: 3
                                )

                            VStack {
                                Spacer()
                                Text("Match outer edges")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .frame(width: cardWidthPoints, height: cardWidthPoints * 0.63)

                        Text("Standard ID card width")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // MARK: Slider
                    VStack(spacing: 12) {
                        Text("Adjust until edges match")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(
                            value: $cardWidthPoints,
                            in: minWidth...maxWidth
                        )
                        .tint(eyevoBlue)
                        .padding(.horizontal)
                        .onChange(of: cardWidthPoints) { _ in
                            errorMessage = nil
                            validateMeasurement()
                        }

                        Text("Tip: If the outline is smaller than your card, increase the size further.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Outline width: \(Int(cardWidthPoints)) pts")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 30) {
                            Button {
                                adjustWidth(by: -fineStep)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(eyevoBlue)
                            }

                            Text("Fine adjust")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button {
                                adjustWidth(by: fineStep)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(eyevoBlue)
                            }
                        }
                    }

                    // MARK: Helpful Notes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Helpful notes")
                            .font(.headline)

                        Text("• This setup takes only a few seconds")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Text("• You can recalibrate anytime later")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Text("• A small mismatch can affect measurement accuracy")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }

            // MARK: Bottom Button
            VStack(spacing: 10) {
                Button(action: beginSelfCheck) {
                    Text("Confirm Calibration")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(isValidMeasurement ? eyevoBlue : Color.gray.opacity(0.4))
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                .disabled(!isValidMeasurement)

                Text("You can recalibrate anytime later if needed.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
        }
        .onAppear {
            validateMeasurement()
        }
        .confirmationDialog(
            "Before continuing",
            isPresented: $showSelfCheck,
            titleVisibility: .visible
        ) {
            Button("Yes, outline matches exactly") {
                saveCalibration()
            }

            Button("Adjust Again", role: .cancel) {
                errorMessage = "Please fine-tune the outline until it matches the card edges exactly."
            }
        } message: {
            Text("Please check one more time that the blue outline matches the outer edges of your card.")
        }
    }

    // MARK: Logic

    private func adjustWidth(by amount: CGFloat) {
        cardWidthPoints = min(max(cardWidthPoints + amount, minWidth), maxWidth)
        errorMessage = nil
        validateMeasurement()
    }

    private func validateMeasurement() {
        let pxPerMM = CalibrationStore.shared.computePxPerMM(
            measuredWidthPoints: cardWidthPoints
        )

        isValidMeasurement = (pxPerMM > 4 && pxPerMM < 20)
    }

    private func beginSelfCheck() {
        let pxPerMM = CalibrationStore.shared.computePxPerMM(
            measuredWidthPoints: cardWidthPoints
        )

        guard pxPerMM > 4 && pxPerMM < 20 else {
            errorMessage = "Calibration looks invalid. Please adjust and try again."
            return
        }

        showSelfCheck = true
    }

    private func saveCalibration() {
        let pxPerMM = CalibrationStore.shared.computePxPerMM(
            measuredWidthPoints: cardWidthPoints
        )

        guard pxPerMM > 4 && pxPerMM < 20 else {
            errorMessage = "Calibration looks invalid. Please adjust and try again."
            return
        }

        CalibrationStore.shared.save(pxPerMM: pxPerMM)
        onCalibrationComplete()
    }
}

// MARK: Instruction Row

private struct InstructionRow: View {

    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.footnote)
        }
    }
}
