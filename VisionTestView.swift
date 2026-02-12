import SwiftUI

// MARK: - Result Sheet Wrapper
private struct OutcomeSheetItem: Identifiable {
    let id = UUID()
    let outcome: TestOutcome
}

struct VisionTestView: View {

    // MARK: - External navigation
    let onExit: (() -> Void)?

    init(onExit: (() -> Void)? = nil) {
        self.onExit = onExit
    }

    // MARK: - ViewModel
    @StateObject private var viewModel = VisionTestViewModel(
        algorithm: StaircaseAlgorithm()
    )

    // MARK: - Result State (SINGLE SOURCE OF TRUTH)
    @State private var resultItem: OutcomeSheetItem? = nil
    @State private var didSaveResult = false
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

            VStack(spacing: 28) {

                // Header
                if viewModel.phase != .completed {
                    Text(isPaused ? "Test paused" : "Prepare for the vision test…")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 12)
                }

                Spacer()

                // Center content
                if isPaused {

                    Text("Paused")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))

                } else {

                    // OPTOTYPE
                    if viewModel.showOptotype,
                       let stimulus = viewModel.currentStimulus {

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

                    // RESPONSE BUTTONS
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

            // MARK: - Footer Controls
            VStack {
                Spacer()

                HStack {

                    // Pause / Resume
                    Button {
                        isPaused.toggle()
                        if !isPaused {
                            optotypeShownAt = nil
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

                    // Exit
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
        .navigationBarBackButtonHidden(true)

        // MARK: - Result Presentation
        .fullScreenCover(item: $resultItem) { item in
            ResultView(
                outcome: item.outcome,
                onRestart: resetTest,
                onDone: {
                    onExit?()
                }
            )
            .onAppear {
                saveOutcomeIfNeeded(item.outcome)
            }
        }

        // MARK: - Exit Confirmation
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

        // MARK: - Lifecycle
        .onAppear {
            guard !didStart else { return }
            didStart = true
            DispatchQueue.main.async {
                viewModel.beginTest()
            }
        }

        // MARK: - Completion → Result
        .onChange(of: viewModel.phase) { _, newPhase in
            guard newPhase == .completed else { return }
            presentResult()
        }

        // Reaction time tracking
        .onChange(of: viewModel.showOptotype) { _, newValue in
            if newValue && !isPaused {
                optotypeShownAt = Date()
            }
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

    private func presentResult() {
        let outcome = viewModel.produceFinalOutcome()
        resultItem = OutcomeSheetItem(outcome: outcome)
    }

    private func saveOutcomeIfNeeded(_ outcome: TestOutcome) {
        guard !didSaveResult else { return }
        didSaveResult = true

        let record = VisionResultRecord(
            id: UUID(),
            date: Date(),
            estimatedLogMAR: outcome.estimatedLogMAR,
            confidence: outcome.confidence,
            isValid: outcome.isValid,
            passed: outcome.passed
        )

        ResultStore.shared.save(record)
    }

    private func resetTest() {
        resultItem = nil
        didSaveResult = false
        optotypeShownAt = nil
        isPaused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            viewModel.restartTest()
        }
    }
}

