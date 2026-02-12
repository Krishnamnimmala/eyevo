
import SwiftUI

struct ResultView: View {

    let outcome: TestOutcome
    let onRestart: () -> Void
    let onDone: (() -> Void)?

    init(
        outcome: TestOutcome,
        onRestart: @escaping () -> Void,
        onDone: (() -> Void)? = nil
    ) {
        self.outcome = outcome
        self.onRestart = onRestart
        self.onDone = onDone
    }

    // MARK: - Derived State

    private var confidence: Double {
        min(max(outcome.confidence ?? 0.0, 0.0), 1.0)
    }

    private var confidencePercent: Int {
        Int(confidence * 100)
    }

    private var confidenceLabel: String {
        switch confidence {
        case 0.75...1.0: return "High confidence"
        case 0.45..<0.75: return "Moderate confidence"
        default: return "Low confidence"
        }
    }

    private var resultTitle: String {
        if !outcome.isValid {
            return "SCREENING INCOMPLETE"
        }
        return outcome.passed ? "VISION SCREEN: PASS" : "VISION SCREEN: REFER"
    }

    private var resultColor: Color {
        if !outcome.isValid { return .gray }
        return outcome.passed ? .green : .orange
    }

    private var resultExplanation: String {
        if !outcome.isValid {
            return "The screening did not collect enough consistent responses to produce a reliable result."
        }
        return outcome.passed
            ? "Your responses were consistent with expected vision screening thresholds."
            : "This screening suggests a follow-up eye exam may be helpful."
    }

    // MARK: - View

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {

                VStack(spacing: 28) {

                    // MARK: Result Header
                    Text(resultTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(resultColor)
                        .multilineTextAlignment(.center)

                    Text(resultExplanation)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    // MARK: Confidence Block (always visible)
                    VStack(spacing: 12) {
                        Text("Result Confidence")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ProgressView(value: confidence)
                            .animation(.easeInOut(duration: 0.6), value: confidence)
                            .tint(resultColor)

                        Text("\(confidenceLabel) (\(confidencePercent)%)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // MARK: Estimated Acuity
                    VStack(spacing: 8) {
                        Text("Estimated Visual Acuity")
                            .font(.headline)

                        if let logMAR = outcome.estimatedLogMAR, outcome.isValid {
                            Text(String(format: "logMAR %.2f", logMAR))
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("Estimated from response consistency near threshold")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // MARK: Disclaimer
                    Text("""
                    This vision screening is not a medical diagnosis.
                    Results are estimates based on user responses and are intended
                    for informational screening purposes only.
                    Consult a qualified eye care professional for a comprehensive eye exam.
                    """)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                    // MARK: Actions
                    VStack(spacing: 14) {
                        Button("Retake Screening", action: onRestart)
                            .buttonStyle(.borderedProminent)

                        Button("Done") {
                            onDone?()
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(
                    maxWidth: 520,
                    minHeight: geo.size.height
                )

            }
        }
        .background(Color(.systemBackground))
    }
}
