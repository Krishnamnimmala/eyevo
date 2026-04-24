import SwiftUI

struct VisionTestView: View {
    
    // MARK: - State
    @StateObject private var viewModel = VisionTestViewModel()
    @State private var showOptotype = false
    @State private var showButtons = false
    @State private var buttonsEnabled = false
    @State private var showResult = false
    @State private var finalOutcome: TestOutcome?
    
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                // Exit
                HStack {
                    Button("Exit Test") {
                        // show exit confirmation
                    }
                    .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // OPTOTYPE
                if showOptotype, let stimulus = viewModel.currentStimulus {
                    Text(stimulus.symbol)
                        .font(.system(size: 140, weight: .bold))
                        .transition(.opacity)
                }
                
                Spacer()
                
                // BUTTONS
                if showButtons {
                    DirectionButtonGrid(
                        enabled: buttonsEnabled,
                        onSelect: handleResponse
                    )
                }
                
                Spacer()
            }
        }
        .onAppear {
            startTrial()
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showResult) {
            if let outcome = finalOutcome {
                ResultView(
                    outcome: outcome,
                    onRestart: {
                        showResult = false
                        viewModel.beginTest()
                        startTrial()
                    }
                )
            }
        }
    }
    
    // MARK: - Trial Flow (INSIDE struct, OUTSIDE body)
    
    func startTrial() {
        showButtons = false
        buttonsEnabled = false
        
        viewModel.getNextStimulus()   // ✅ FUNCTION CALL
        showOptotype = true
        
        let exposure = Double.random(in: 0.85...1.15)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + exposure) {
            showOptotype = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showButtons = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    buttonsEnabled = true
                }
            }
        }
    }
    
    
    func handleResponse(_ direction: Direction) {
        guard buttonsEnabled else { return }
        
        buttonsEnabled = false
        showButtons = false
        
        viewModel.submitResponse(direction)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.getNextStimulus()
            startTrial()
        }
    }
    
}
    
    

