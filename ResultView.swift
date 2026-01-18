import SwiftUI

struct ResultView: View {

    let outcome: TestOutcome
    let onRestart: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var resultTitle: String {
        outcome.passed ? "VISION SCREEN: PASS" : "VISION SCREEN: REFER"
    
        
    }

    private var resultColor: Color {
        outcome.passed ? .green : .orange
    }

    private var confidence: Double {
        let raw = outcome.confidence ?? 0.0
        return min(max(raw, 0.0), 1.0)
    }

    private var resultExplanation: String {
        outcome.passed
        ? "Your screening responses were consistent with expected vision thresholds."
        : "This screening suggests a follow-up eye exam may be helpful."
    }

    var body: some View {
        VStack(spacing: 28) {

            VStack(spacing: 18) {

                Text("Vision Screening Result")
                    .font(.title3)
                    .fontWeight(.semibold)

                // PASS / REFER
                Text(resultTitle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(resultColor)
                    .accessibilityLabel(
                        outcome.passed
                        ? "Vision screening passed"
                        : "Vision screening recommends follow-up"
                    )

                
                Text(resultExplanation)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)


                // Confidence Indicator
                VStack(spacing: 6) {
                    Text("Confidence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ProgressView(value: confidence)
                        .tint(resultColor)
                        .accessibilityLabel("Confidence level")
                        .accessibilityValue("\(Int(confidence * 100)) percent")


                    Text("\(Int(confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Acuity
                VStack(spacing: 8) {
                    Text("Estimated Visual Acuity")
                        .font(.headline)

                    if let logMAR = outcome.estimatedLogMAR {
                        Text(String(format: "logMAR %.2f", logMAR))
                            .font(.title2)
                    } else {
                        Text(resultTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(resultColor)
                    }
                }

                // FDA-safe disclaimer
                Text(disclaimerText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.75)
                    .padding(.horizontal)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 6)
            )
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button("Retake Screening") {
                    onRestart()
                }
                .buttonStyle(.borderedProminent)

                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .dynamicTypeSize(.small ... .xxLarge)
    }

    private var disclaimerText: String {
        """
        This vision screening is not a medical diagnosis.
        Results are for informational purposes only and should not be used
        to diagnose or treat any eye condition.
        Consult a qualified eye care professional for a comprehensive exam.
        """
    }
}
