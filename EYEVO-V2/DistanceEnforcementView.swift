import SwiftUI

struct DistanceEnforcementView: View {

    // Passed from View
    let currentEye: Eye
    let onContinue: () -> Void
    let onBack: () -> Void

    // Countdown state
    @State private var isCountingDown = false
    @State private var countdown = 3
    @State private var canContinue = false

    var body: some View {

        VStack(spacing: 20) {

            // Eye instruction
            Text(currentEye == .left
                 ? "Cover your RIGHT eye"
                 : "Cover your LEFT eye")
                .font(.headline)

            Text("Hold the phone at arm’s length (40 cm)")
                .font(.subheadline)
                .multilineTextAlignment(.center)

            if isCountingDown {
                Text("\(countdown)")
                    .font(.largeTitle)
                    .bold()
            }

            Button("Continue") {
                onContinue()
            }
            .disabled(!canContinue)

            Button("Back") {
                onBack()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {

        guard !isCountingDown else { return }

        isCountingDown = true
        countdown = 3
        canContinue = false

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1

            if countdown == 0 {
                timer.invalidate()
                isCountingDown = false
                canContinue = true
            }
        }
    }
}

#Preview {
    DistanceEnforcementView(
        currentEye: .left,
        onContinue: {},
        onBack: {}
    )
}
