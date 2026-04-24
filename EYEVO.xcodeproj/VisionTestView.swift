import SwiftUI

// MARK: - Result Sheet Wrapper
private struct OutcomeSheetItem: Identifiable {
    let id = UUID()
    let outcome: TestOutcome
}

struct VisionTestView: View {

    // MARK: - Beta Detection
    private var isBetaBuild: Bool {
        true   // Change later to sandboxReceipt detection if desired
    }

    // MARK: - External navigation
    let onExit: (() -> Void)?

    init(onExit: (() -> Void)? = nil) {
        self.onExit = onExit
    }

    // MARK: - ViewModel
    @StateObject private var viewModel = VisionTestViewModel(
        algorithm: StaircaseAlgorithm()
    )

    // MARK: - Result State
    @State private var resultItem: OutcomeSheetItem? = nil
    @State private var didSaveResult = false
    @State private var didPresentResult = false
    @State private var didStart = false

    // MARK: - Pause / Exit
    @State private var isPaused = false
    @State private var showExitConfirm = false

    // MARK: - Response timing
    @State private var optotypeShownAt: Date? = nil

    // MARK: - Body
    var body: some View {

        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 22) {

                // Beta Badge
                if isBetaBuild {
                    Text("BETA Screening in Progress")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                        .padding(.top, 8)
                }

                // Header
                if viewModel.phase != .completed {
                    Text(isPaused ? "Test paused" : "Follow the direction of the symbol")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 12)
                }

                Spacer()

                if isPaused {

                    Text("Paused")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))

                } else {

                    // Distance enforcement
                    if viewModel.requiresEnforcement {
                        DistanceEnforcementView(
                            currentEye: viewModel.currentEye,
                            onContinue: {
                                viewModel.confirmEnforcement()
                            },
                            onBack: {
                                onExit?()
                            }
                        )
                    }

                    // Stimulus
                    stimulusBlock()

                    // Response Buttons
                    if viewModel.showButtons {
                        DirectionButtonGrid(
                            enabled: viewModel.buttonsEnabled,
                            onSelect: handleResponse
                        )
                    }
                }

                Spacer()
            }
            .padding()

            footerControls()
        }
        .navigationBarBackButtonHidden(true)

        // Result Presentation
        .fullScreenCover(item: $resultItem) { item in
            ResultView(
                outcome: item.outcome,
                onRestart: resetTest,
                onDone: { onExit?() }
            )
            .onAppear {
                saveOutcomeIfNeeded(item.outcome)
            }
        }

        // Exit Confirmation
        .confirmationDialog(
            "Exit vision test?",
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("Exit Test", role: .destructive) {
                onExit?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your current test progress will be lost.")
        }

        // Lifecycle
        .onAppear {
            guard !didStart else { return }
            didStart = true
            DispatchQueue.main.async {
                viewModel.beginTest()
            }
        }

        .onChange(of: viewModel.phase) { _, newPhase in
            guard newPhase == .completed else { return }
            presentResultIfNeeded()
        }

        .onChange(of: viewModel.currentStimulus?.id) { _, _ in
            guard !isPaused else { return }
            guard viewModel.currentStimulus != nil else { return }
            optotypeShownAt = Date()
        }
    }

    // MARK: - Stimulus Block
    @ViewBuilder
    private func stimulusBlock() -> some View {

        if let stimulus = viewModel.currentStimulus {

            VStack(spacing: 18) {

                if stimulus.optotype == .landoltC {
                    LandoltCView(
                        openingDirection: stimulus.openingDirection,
                        size: stimulus.pixelSize
                    )
                    .id(stimulus.id)

                } else {
                    ArrowOptotypeView(
                        direction: stimulus.openingDirection,
                        size: stimulus.pixelSize,
                        logMAR: stimulus.sizeLogMAR
                    )
                    .id(stimulus.id)
                }
            }

        } else {

            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.85))
        }
    }

    // MARK: - Footer Controls
    @ViewBuilder
    private func footerControls() -> some View {

        VStack {
            Spacer()

            HStack {

                Button {
                    isPaused.toggle()
                    if !isPaused {
                        optotypeShownAt = Date()
                    }
                } label: {
                    Label(
                        isPaused ? "Resume" : "Pause",
                        systemImage: isPaused ? "play.circle" : "pause.circle"
                    )
                }
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
                .foregroundColor(.white)
                .clipShape(Capsule())

                Spacer()

                Button {
                    showExitConfirm = true
                } label: {
                    Label("Exit", systemImage: "xmark.circle")
                }
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.20))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Actions
    private func handleResponse(_ direction: ResponseDirection) {

        guard !isPaused else { return }
        guard viewModel.buttonsEnabled else { return }
        guard viewModel.phase != .completed else { return }

        let rtMs: Int = {
            guard let shown = optotypeShownAt else { return 0 }
            return Int(Date().timeIntervalSince(shown) * 1000.0)
        }()

        viewModel.submitResponse(direction, rtMs: rtMs)

        optotypeShownAt = nil
    }

    private func presentResultIfNeeded() {
        guard !didPresentResult else { return }
        didPresentResult = true
        let outcome = viewModel.produceFinalOutcome()
        resultItem = OutcomeSheetItem(outcome: outcome)
    }

    private func saveOutcomeIfNeeded(_ outcome: TestOutcome) {
        guard !didSaveResult else { return }
        didSaveResult = true

        let record = VisionResultRecord(
            startTime: outcome.startTime ?? Date(),
            endTime: outcome.endTime,
            duration: outcome.duration,
            leftEyeLogMAR: outcome.leftEyeLogMAR,
            rightEyeLogMAR: outcome.rightEyeLogMAR,
            leftEyePassed: outcome.leftEyePassed,
            rightEyePassed: outcome.rightEyePassed,
            confidence: outcome.confidence,
            overallPassed: outcome.overallPassed
        )

        ResultStore.shared.save(record)
    }

    private func resetTest() {
        resultItem = nil
        didSaveResult = false
        didPresentResult = false
        optotypeShownAt = nil
        isPaused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            viewModel.restartTest()
        }
    }
}
