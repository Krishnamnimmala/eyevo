import SwiftUI

private struct OutcomeSheetItem: Identifiable {
    let id = UUID()
    let outcome: TestOutcome
}

struct VisionTestView: View {
    private var isBetaBuild: Bool { true }

    let onExit: (() -> Void)?

    init(onExit: (() -> Void)? = nil) {
        self.onExit = onExit
    }

    @StateObject private var viewModel = VisionTestViewModel(
        algorithm: StaircaseAlgorithm()
    )

    @State private var resultItem: OutcomeSheetItem? = nil
    @State private var didSaveResult = false
    @State private var didPresentResult = false
    @State private var didStart = false
    @State private var showExitConfirm = false
    @State private var optotypeShownAt: Date? = nil
    @State private var lastResponseCorrect: Bool? = nil
    @State private var showResponseFlash = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let compact = h < 780
            let veryCompact = h < 700

            let horizontalPadding: CGFloat = compact ? 14 : 16
            let topPadding: CGFloat = veryCompact ? 2 : (compact ? 4 : 8)
            let contentSpacing: CGFloat = veryCompact ? 6 : (compact ? 8 : 12)
            let headerBottomSpacing: CGFloat = veryCompact ? 4 : (compact ? 6 : 10)
            let stimulusMinHeight: CGFloat = veryCompact ? 96 : (compact ? 125 : 170)
            let padHeight: CGFloat = veryCompact ? 220 : (compact ? 250 : 285)
            let reserveHeight: CGFloat = veryCompact ? 96 : (compact ? 112 : 136)
        
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.07),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection(compact: compact, veryCompact: veryCompact)
                        .padding(.top, topPadding)
                    
                    Color.clear
                        .frame(height: headerBottomSpacing)
                    if viewModel.requiresEnforcement {
                        Spacer(minLength: 0)

                        DistanceEnforcementView(
                            currentEye: viewModel.currentEye,
                            onContinue: {
                                optotypeShownAt = nil
                                clearResponseFeedback()
                                viewModel.confirmEnforcement()
                            },
                            onBack: {
                                onExit?()
                            }
                        )

                        Spacer(minLength: 0)
                    } else {
                        stimulusBlock(minHeight: stimulusMinHeight)

                        Spacer(minLength: veryCompact ? 6 : 10)

                        if viewModel.showButtons {
                            VStack(spacing: veryCompact ? 6 : 8) {
                                
                                // 🔼 Move pad UP
                                    DirectionalInputPad { direction in
                                        handleDirectionalPadResponse(direction)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: padHeight)
                                    .offset(y: -18)   // 🔑 THIS MOVES PAD UP (adjust -10 to -18 if needed)
                                    .opacity(viewModel.buttonsEnabled ? 1.0 : 0.55)
                                    .allowsHitTesting(viewModel.buttonsEnabled && viewModel.phase != .completed)
                                
                                .frame(maxWidth: .infinity)
                                .frame(height: padHeight)
                                .opacity(viewModel.buttonsEnabled ? 1.0 : 0.55)
                                .allowsHitTesting(viewModel.buttonsEnabled && viewModel.phase != .completed)

                                NotSureButton(
                                        enabled: viewModel.buttonsEnabled && viewModel.phase != .completed,
                                        isCompact: compact,
                                        action: {
                                            handleNotSure()
                                        }
                                    )
                                .padding(.top, -10)
                                
                                // 🔑 pulls button upward
                                }
                            
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            Color.clear
                                .frame(height: reserveHeight)
                        }

                        Spacer(minLength: veryCompact ? 4 : 8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 10))

                if showResponseFlash, let correct = lastResponseCorrect {
                    responseFlashOverlay(correct: correct)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.18), value: viewModel.showButtons)
        .animation(.easeInOut(duration: 0.18), value: viewModel.showOptotype)
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
        .onChange(of: viewModel.showOptotype) { _, isShowing in
            if isShowing, viewModel.currentStimulus != nil {
                optotypeShownAt = Date()
                clearResponseFeedback()
            }
        }
        .onChange(of: viewModel.currentStimulus?.id) { _, newID in
            guard newID != nil else {
                optotypeShownAt = nil
                return
            }
        }
    }

    @ViewBuilder
    private func headerSection(compact: Bool, veryCompact: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: veryCompact ? 4 : 6) {
                if isBetaBuild {
                    Text("BETA Screening in Progress")
                        .font(veryCompact ? .caption2 : .caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, veryCompact ? 10 : 12)
                        .padding(.vertical, veryCompact ? 5 : 6)
                        .background(Color.orange.opacity(0.18))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }

                if viewModel.phase != .completed {
                    Text(instructionText)
                        .font(veryCompact ? .title3 : (compact ? .title2 : .largeTitle))
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
            }

            Spacer(minLength: 8)

            Button {
                showExitConfirm = true
            } label: {
                Label("Exit", systemImage: "xmark.circle")
                    .font(veryCompact ? .headline : .title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal, veryCompact ? 14 : 16)
                    .padding(.vertical, veryCompact ? 10 : 12)
                    .background(Color.red.opacity(0.22))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .fixedSize()
        }
    }
    
    private var instructionText: String {
        guard let optotype = viewModel.currentStimulus?.optotype else {
            return "Follow the on-screen instructions"
        }

        switch optotype {
        case .arrows:
            return "Select the direction of the arrow is pointing"

        case .landoltC:
            return "Select the direction of the gap in the circle"
        }
    }
    
    @ViewBuilder
    private func stimulusBlock(minHeight: CGFloat) -> some View {
        ZStack {
            if viewModel.showOptotype, let stimulus = viewModel.currentStimulus {
                VStack {
                    Spacer(minLength: 0)

                    Group {
                        if stimulus.optotype == .landoltC {
                            
                            let dynamicGap = viewModel.currentLogMAR <= 0.2 ? 20.0 : 22.0
                           
                        
                            VStack(spacing: 8) {

                                LandoltCView(
                                    openingDirection: stimulus.openingDirection,
                                    size: stimulus.pixelSize,
                                    gapAngle: dynamicGap,
                                    ringThicknessRatio: 0.22
                                )
                                .id(stimulus.id)

                                Text("Size: \(Int(stimulus.pixelSize)) px")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .opacity(0.7)
                            }
                        } else {
                            ArrowOptotypeView(
                                direction: stimulus.openingDirection,
                                size: stimulus.pixelSize,
                                logMAR: stimulus.sizeLogMAR
                            )
                            .id(stimulus.id)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(showResponseFlash ? 0.985 : 1.0)
                .opacity(viewModel.showOptotype ? 1.0 : 0.0)
                .transition(.opacity)

            } else if !viewModel.showButtons && viewModel.phase != .completed {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.85))
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity)
    }

    
    @ViewBuilder
    private func responseFlashOverlay(correct: Bool) -> some View {
        Color(correct ? .green : .red)
            .opacity(0.10)
            .ignoresSafeArea()
    }

    private func handleDirectionalPadResponse(_ direction: DirectionalPadDirection) {
        let mapped: ResponseDirection

        switch direction {
        case .up: mapped = .up
        case .upRight: mapped = .upRight
        case .right: mapped = .right
        case .downRight: mapped = .downRight
        case .down: mapped = .down
        case .downLeft: mapped = .downLeft
        case .left: mapped = .left
        case .upLeft: mapped = .upLeft
        }

        handleResponse(mapped)
    }

    private func handleResponse(_ direction: ResponseDirection) {
        guard viewModel.buttonsEnabled else { return }
        guard viewModel.phase != .completed else { return }
        guard let stimulus = viewModel.currentStimulus else { return }

        let rtMs: Int = {
            guard let shown = optotypeShownAt else { return 0 }
            return max(0, Int(Date().timeIntervalSince(shown) * 1000.0))
        }()

        let wasCorrect: Bool = {
            if stimulus.optotype == .landoltC {
                return direction == stimulus.openingDirection
            } else {
                return direction == stimulus.openingDirection ||
                direction.cardinalEquivalent == stimulus.openingDirection.cardinalEquivalent
            }
        }()

        showFeedback(correct: wasCorrect)
        viewModel.submitResponse(direction, rtMs: rtMs)
        optotypeShownAt = nil
    }

    private func handleNotSure() {
        guard viewModel.buttonsEnabled else { return }
        guard viewModel.phase != .completed else { return }

        let rtMs: Int = {
            guard let shown = optotypeShownAt else { return 0 }
            return max(0, Int(Date().timeIntervalSince(shown) * 1000.0))
        }()

        clearResponseFeedback()
        viewModel.submitNotSure(rtMs: rtMs)
        optotypeShownAt = nil
    }

    private func showFeedback(correct: Bool) {
        lastResponseCorrect = correct

        withAnimation(.easeInOut(duration: 0.10)) {
            showResponseFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeOut(duration: 0.16)) {
                showResponseFlash = false
            }
        }
    }

    private func clearResponseFeedback() {
        lastResponseCorrect = nil
        showResponseFlash = false
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
            eyevoID: EyevoIDStore.shared.eyevoID,
            startTime: outcome.startTime,
            endTime: outcome.endTime,
            duration: outcome.durationSeconds,
            leftEyeLogMAR: outcome.leftEyeLogMAR,
            rightEyeLogMAR: outcome.rightEyeLogMAR,
            leftEyePassed: outcome.leftEyePassed,
            rightEyePassed: outcome.rightEyePassed,
            confidence: outcome.confidence,
            overallPassed: outcome.overallPassed,
            notSureCount: outcome.notSureCount,
            totalResponseCount: outcome.totalResponseCount,
            reliabilityLabel: outcome.reliabilityLabel
        )

        ResultStore.shared.save(record)
    }

    
    private func resetTest() {
        resultItem = nil
        didSaveResult = false
        didPresentResult = false
        optotypeShownAt = nil
        clearResponseFeedback()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            viewModel.restartTest()
            
        }
    }
}

