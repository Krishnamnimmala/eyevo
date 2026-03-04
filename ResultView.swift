import SwiftUI

struct ResultView: View {

    let outcome: TestOutcome
    let onRestart: () -> Void
    let onDone: (() -> Void)?
    let eyevoID = EyevoIDStore.shared.eyevoID

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
        // If your TestOutcome.confidence is non-optional, this is correct.
        // If it is optional in your model, change to: min(max(outcome.confidence ?? 0.0, 0.0), 1.0)
        min(max(outcome.confidence, 0.0), 1.0)
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

    // Overall result now uses per-eye overallPassed (recommended).
    private var overallPassed: Bool {
        // If your new TestOutcome has overallPassed, prefer it.
        // If your model still uses `passed`, replace `outcome.overallPassed` with `outcome.passed`.
        outcome.overallPassed
    }

    private var isValid: Bool {
        // If your TestOutcome still has isValid, keep using it.
        // If not, you can return true (or wire your own validity rules).
        outcome.isValid
    }

    private var resultTitle: String {
        if !isValid { return "SCREENING INCOMPLETE" }
        return overallPassed ? "VISION SCREEN: PASS" : "VISION SCREEN: REFER"
    }

    private var resultColor: Color {
        if !isValid { return .gray }
        return overallPassed ? .green : .orange
    }

    private var resultExplanation: String {
        if !isValid {
            return "The screening did not collect enough consistent responses to produce a reliable result."
        }
        return overallPassed
            ? "Your responses were consistent with expected vision screening thresholds."
            : "This screening suggests a follow-up eye exam may be helpful."
    }

    // MARK: - Time Formatting

    private var formattedStartTime: String {
        guard let start = outcome.startTime else { return "-" }
        return start.formatted(date: .abbreviated, time: .standard)
    }

    private var formattedEndTime: String {
        guard let end = outcome.endTime else { return "-" }
        return end.formatted(date: .abbreviated, time: .standard)
    }

    private var formattedDuration: String {
        guard let duration = outcome.duration else { return "-" }

        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Per-eye helpers

    private func eyeStatusText(passed: Bool?) -> String {
        guard let passed else { return "-" }
        return passed ? "PASS" : "REFER"
    }

    private func eyeStatusColor(passed: Bool?) -> Color {
        guard let passed else { return .secondary }
        return passed ? .green : .orange
    }

    private func eyeLogMARText(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "logMAR %.2f", value)
    }

    // MARK: - View

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {

                VStack(spacing: 16) {

                    // MARK: Result Header
                    Text(resultTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(resultColor)
                        .multilineTextAlignment(.center)

                    Text(resultExplanation)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    // MARK: Confidence Block (always visible)
                    VStack(spacing: 6) {
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

                    // MARK: Per-Eye Results
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Per-Eye Results")
                            .font(.headline)

                        // Left Eye
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Left Eye")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(eyeStatusText(passed: outcome.leftEyePassed))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(eyeStatusColor(passed: outcome.leftEyePassed))
                            }

                            Text(eyeLogMARText(outcome.leftEyeLogMAR))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }

                        // Right Eye
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Right Eye")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(eyeStatusText(passed: outcome.rightEyePassed))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(eyeStatusColor(passed: outcome.rightEyePassed))
                            }

                            Text(eyeLogMARText(outcome.rightEyeLogMAR))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text("Eyevo ID: \(eyevoID)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                        }

                        Divider()

                        // Overall
                        HStack {
                            Text("Overall")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(overallPassed ? "PASS" : "REFER")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(overallPassed ? .green : .orange)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // MARK: Test Timing
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Details")
                            .font(.headline)

                        HStack {
                            Text("Started:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedStartTime)
                        }

                        HStack {
                            Text("Completed:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedEndTime)
                        }

                        HStack {
                            Text("Duration:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedDuration)
                        }
                    }
                    .font(.footnote)
                    .padding(.horizontal)

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
