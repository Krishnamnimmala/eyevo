import SwiftUI
import Combine

struct VisionTestView: View {

    @StateObject private var viewModel: VisionTestViewModel

    @State private var showOptotype = false
    @State private var showButtons = false
    @State private var buttonsEnabled = false

    @State private var showResult = false
    @State private var finalOutcome: TestOutcome?
    @State private var didPresentResult = false
    @State private var didStart = false

    // New initializer to allow injecting algorithm selection
    init(useQuest: Bool = false) {
        if useQuest {
            _viewModel = StateObject(wrappedValue: VisionTestViewModel(algorithm: QuestAlgorithm()))
        } else {
            _viewModel = StateObject(wrappedValue: VisionTestViewModel())
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {

                // PREPARING
                if viewModel.phase == .preparing {
                    Text("Prepare for the vision test…")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 12)
                }

                Spacer()

                // INTERACTIVE (gatekeeper + running)
                if (viewModel.phase == .preparing || viewModel.phase == .running),
                   let stimulus = viewModel.currentStimulus,
                   showOptotype {

                    Text(stimulus.symbol)
                        .font(.system(size: 120, weight: .bold))
                        .rotationEffect(rotation(for: stimulus.expectedAnswer))

                } else if viewModel.phase == .preparing {
                    Text("Preparing test…")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.70))
                }

                Spacer()

                if (viewModel.phase == .preparing || viewModel.phase == .running) && showButtons {
                    DirectionButtonGrid(
                        enabled: buttonsEnabled,
                        onSelect: handleResponse
                    )
                    .padding(.bottom, 34)
                }

                
            }
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true

            viewModel.beginTest()
            viewModel.getNextStimulus()
            startTrial()
        }
        .onReceive(viewModel.phasePublisher) { newPhase in
            if newPhase == .running {
                startTrial()
            }

            if newPhase == .completed {
                presentResultIfNeeded()
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showResult) {
            if let outcome = finalOutcome {
                ResultView(outcome: outcome, onRestart: resetTest)
            }
        }
    }

    // MARK: - Trial Loop

    private func startTrial() {
        guard viewModel.phase == .running || viewModel.phase == .preparing else { return }

        showButtons = false
        buttonsEnabled = false
        showOptotype = false

        if viewModel.currentStimulus == nil {
            viewModel.getNextStimulus()
        }

        guard viewModel.currentStimulus != nil else { return }

        showOptotype = true

        let exposure = Double.random(in: 0.85...1.15)
        DispatchQueue.main.asyncAfter(deadline: .now() + exposure) {
            guard viewModel.phase != .completed else { return }

            showOptotype = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                guard viewModel.phase != .completed else { return }
                showButtons = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                    guard viewModel.phase != .completed else { return }
                    buttonsEnabled = true
                }
            }
        }
    }

    private func handleResponse(_ direction: ResponseDirection) {
        guard buttonsEnabled else { return }

        buttonsEnabled = false
        showButtons = false

        viewModel.submitResponse(direction)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            startTrial()
        }
    }

    private func presentResultIfNeeded() {
        guard !didPresentResult else { return }
        didPresentResult = true

        finalOutcome = viewModel.finalizeSession()
        showResult = true
    }

    private func resetTest() {
        showResult = false
        finalOutcome = nil
        didPresentResult = false

        showOptotype = false
        showButtons = false
        buttonsEnabled = false

        viewModel.beginTest()
        viewModel.getNextStimulus()
        startTrial()
    }
    
    //rotation helper (UI-only)
    private func rotation(for direction: ResponseDirection) -> Angle {
        switch direction {
        case .up:    return .degrees(0)
        case .right: return .degrees(90)
        case .down:  return .degrees(180)
        case .left:  return .degrees(270)
        }
    }

}
