import SwiftUI

struct ResultView: View {

    let outcome: TestOutcome
    let onRestart: () -> Void
    let onDone: (() -> Void)?

    private let eyevoID = EyevoIDStore.shared.eyevoID

    init(
        outcome: TestOutcome,
        onRestart: @escaping () -> Void,
        onDone: (() -> Void)? = nil
    ) {
        self.outcome = outcome
        self.onRestart = onRestart
        self.onDone = onDone
    }

    // MARK: - Display Status

    private enum DisplayStatus: String {
        case pass = "PASS"
        case refer = "REFER"
        case retest = "RETEST"
    }

    private var displayStatus: DisplayStatus {
        // If both eyes passed, always show PASS in UI.
        if (outcome.leftEyePassed == true) && (outcome.rightEyePassed == true) {
            return .pass
        }

        // If one eye passed and the other did not, show REFER.
        if (outcome.leftEyePassed == true && outcome.rightEyePassed == false) ||
            (outcome.leftEyePassed == false && outcome.rightEyePassed == true) {
            return .refer
        }

        // If engine says overall passed, respect it.
        if outcome.overallPassed {
            return .pass
        }

        // If result is valid but not passing, show REFER.
        if outcome.isValid {
            return .refer
        }

        // Otherwise show RETEST.
        return .retest
    }

    private var confidence: Double {
        min(max(outcome.confidence, 0.0), 1.0)
    }

    private var confidencePercent: Int {
        Int((confidence * 100).rounded())
    }

    private var confidenceLabel: String {
        outcome.confidenceLabel
    }

    private var bothEyesPassedThreshold: Bool {
        (outcome.leftEyePassed == true) && (outcome.rightEyePassed == true)
    }

    private var hasMixedEyeOutcome: Bool {
        (outcome.leftEyePassed == true && outcome.rightEyePassed == false) ||
        (outcome.leftEyePassed == false && outcome.rightEyePassed == true)
    }

    private var overallStatusText: String {
        displayStatus.rawValue
    }

    private var resultTitle: String {
        switch displayStatus {
        case .pass:
            return "VISION SCREEN: PASS"
        case .refer:
            return "VISION SCREEN: REFER"
        case .retest:
            return "VISION SCREEN: RETEST"
        }
    }

    private var resultColor: Color {
        switch displayStatus {
        case .pass:
            return .green
        case .refer:
            return .red
        case .retest:
            return .orange
        }
    }

    private var resultExplanation: String {
        switch displayStatus {
        case .pass:
            return "Your responses met the screening threshold in both eyes under current testing conditions."

        case .refer:
            if hasMixedEyeOutcome {
                return "One eye met the screening threshold while the other did not. A follow-up eye exam is recommended."
            }
            return "This screening indicates that a follow-up eye exam is recommended."

        case .retest:
            if bothEyesPassedThreshold {
                return "Both eyes met the screening threshold, but the session quality was not strong enough for a final overall decision. Retesting is recommended."
            }

            if hasMixedEyeOutcome {
                return "Per-eye findings were mixed, but the session quality was not strong enough for a final overall decision. Retesting is recommended."
            }

            return "The screening result is not reliable enough for a final decision. Please retest under proper conditions."
        }
    }

    private var reliabilityText: String {
        outcome.reliabilityLabel
    }

    private var reliabilityColor: Color {
        switch outcome.reliabilityLabel.lowercased() {
        case "high":
            return .green
        case "moderate":
            return .orange
        case "low":
            return .red
        default:
            return .secondary
        }
    }

    private var responseQualityNote: String {
        if outcome.totalResponseCount == 0 {
            return "No response quality information available."
        }

        if outcome.notSureCount == 0 {
            return "No unsure responses were recorded during this screening."
        }

        if outcome.resultMode == .floorEstimate {
            return "A high number of unsure responses with reduced optotype resolution was observed. This is treated as a severe blur estimate."
        }

        switch outcome.reliabilityLabel.lowercased() {
        case "low":
            return "A higher number of unsure responses was recorded. Retesting is recommended."
        case "moderate":
            return "Some unsure responses were recorded. Interpret results with caution."
        default:
            return "Response quality was acceptable for this screening."
        }
    }

    private var sessionConsistencyNote: String? {
        if displayStatus == .retest && bothEyesPassedThreshold {
            return "Per-eye thresholds appear acceptable, but overall session consistency was not strong enough for a final overall pass."
        }

        if displayStatus == .retest && hasMixedEyeOutcome {
            return "Per-eye findings and response consistency were not strong enough to support a final overall determination."
        }

        return nil
    }

    private var formattedStartTime: String {
        outcome.startTime.formatted(date: .abbreviated, time: .standard)
    }

    private var formattedEndTime: String {
        outcome.endTime.formatted(date: .abbreviated, time: .standard)
    }

    private var formattedDuration: String {
        let totalSeconds = Int(outcome.durationSeconds.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    private func eyeStatusText(passed: Bool?) -> String {
        guard let passed else { return "-" }
        return passed ? "PASS" : "REFER"
    }

    private func eyeStatusColor(passed: Bool?) -> Color {
        guard let passed else { return .secondary }
        return passed ? .green : .red
    }

    private func eyeLogMARText(_ value: Double?) -> String {
        guard let value else { return "-" }

        if outcome.resultMode == .floorEstimate && value >= 0.8 {
            return String(format: "Estimated acuity ≥ logMAR %.2f", value)
        }

        return String(format: "logMAR %.2f", value)
    }

    private func eyeSnellenApprox(_ value: Double?) -> String {
        guard let value else { return "-" }

        let denom = snellenDenominator(from: value)

        if outcome.resultMode == .floorEstimate && value >= 0.8 {
            return "Approx. worse than 20/\(denom)"
        }

        return "Approx. 20/\(denom)"
    }

    private func snellenDenominator(from logMAR: Double) -> Int {
        max(1, Int((20.0 * pow(10.0, logMAR)).rounded()))
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {

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

                    VStack(spacing: 8) {
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
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response Reliability")
                            .font(.headline)

                        HStack {
                            Text("Reliability")
                            Spacer()
                            Text(reliabilityText)
                                .fontWeight(.semibold)
                                .foregroundColor(reliabilityColor)
                        }

                        HStack {
                            Text("Not Sure Responses")
                            Spacer()
                            Text("\(outcome.notSureCount)")
                        }

                        HStack {
                            Text("Total Responses")
                            Spacer()
                            Text("\(outcome.totalResponseCount)")
                        }

                        HStack {
                            Text("Max Consecutive Not Sure")
                            Spacer()
                            Text("\(outcome.maxConsecutiveNotSure)")
                        }

                        Text(outcome.interpretation)
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Text(responseQualityNote)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per-Eye Results")
                            .font(.headline)

                        eyeBlock(
                            title: "Left Eye",
                            logMAR: outcome.leftEyeLogMAR,
                            passed: outcome.leftEyePassed
                        )

                        eyeBlock(
                            title: "Right Eye",
                            logMAR: outcome.rightEyeLogMAR,
                            passed: outcome.rightEyePassed
                        )

                        if let sessionConsistencyNote {
                            Text(sessionConsistencyNote)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }

                        Divider()

                        HStack {
                            Text("Overall")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(overallStatusText)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(resultColor)
                        }

                        HStack {
                            Text("Eyevo ID")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(eyevoID)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Details")
                            .font(.headline)

                        HStack {
                            Text("Started")
                            Spacer()
                            Text(formattedStartTime)
                        }

                        HStack {
                            Text("Completed")
                            Spacer()
                            Text(formattedEndTime)
                        }

                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formattedDuration)
                        }
                    }
                    .font(.footnote)
                    .padding(.horizontal)

                    Text(outcome.disclaimerText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 14) {
                        Button("Retake Screening", action: onRestart)
                            .buttonStyle(.borderedProminent)

                        if let onDone {
                            Button("Done", action: onDone)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 520, minHeight: geo.size.height)
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Eye Block

    private func eyeBlock(title: String, logMAR: Double?, passed: Bool?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(eyeStatusText(passed: passed))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(eyeStatusColor(passed: passed))
            }

            Text(eyeLogMARText(logMAR))
                .font(.footnote)
                .foregroundColor(.secondary)

            Text(eyeSnellenApprox(logMAR))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
