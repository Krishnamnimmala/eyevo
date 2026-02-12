import SwiftUI

struct DistanceEnforcementView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isCountingDown = false
    @State private var countdown = 3
    @State private var canContinue = false

    var body: some View {
        VStack(spacing: 16) {
            
            // MARK: - Header (Back button moved to TOP CORNER)
            // MARK: - Header
            VStack(alignment: .leading, spacing: 6) {

                Button {
                    onBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                }
                .disabled(isCountingDown)

                Text("Set Viewing Distance")
                    .font(.title2.bold())
                    .padding(.top, 4) // 👈 moves title down one clean line
            }
            .padding(.leading, 12)
            .padding(.trailing, 20) // keeps text aligned nicely
            
            .padding(.top, 8)


            // MARK: - Combined Instruction + Distance (ONE BOX)
            VStack(alignment: .leading, spacing: 12) {
                Label("How to position the phone", systemImage: "ruler")
                    .font(.system(size: 16, weight: .semibold))

                Text(
                    "Hold the phone at about arm's length. Keep your head still and the phone centered in front of your eyes."
                )
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Divider()

                VStack(spacing: 8) {
                    Text("≈ 40 cm / 16 in")
                        .font(.headline)

                    HStack(spacing: 10) {
                        Image(systemName: "person.fill")
                        RoundedRectangle(cornerRadius: 6)
                            .frame(height: 10)
                        Image(systemName: "iphone")
                    }
                    .foregroundStyle(.secondary)

                    Text("Use this as a positioning guide — not a physical measurement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true) // ✅ Full line now visible
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 16)

            // MARK: - Ready + Continue (SIDE BY SIDE)
            HStack(spacing: 12) {
                Button {
                    startCountdown()
                } label: {
                    HStack {
                        if isCountingDown {
                            ProgressView()
                            Text("Starting in \(countdown)")
                        } else if canContinue {
                            Label("Distance confirmed", systemImage: "checkmark.circle.fill")
                        } else {
                            Label("Ready", systemImage: "circle")
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isCountingDown || canContinue)

                Spacer()

                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canContinue || isCountingDown)
                .opacity(canContinue ? 1.0 : 0.4)
            }
            .padding(.horizontal, 20)

            // MARK: - Scrollable IMPORTANT DISCLAIMER (FIXED - now scrolls + visible)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Important", systemImage: "exclamationmark.triangle")
                        .font(.system(size: 14, weight: .semibold))

                    Text("""
                    This is a vision screening tool and does not diagnose eye disease or replace a comprehensive eye examination.
                    If you have concerns about your vision, please consult a qualified eye care professional.
                    """)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
            }
            .frame(height: 100) // Reduced height = more scroll visibility
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                    ) // ✅ Scroll indicator visible
            )
            .padding(.horizontal, 16)

            Spacer(minLength: 8)
        }
        .background(Color(.systemBackground))
    }

    private func startCountdown() {
        guard !isCountingDown else { return }
        isCountingDown = true
        countdown = 3

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
        onContinue: {},
        onBack: {}
    )
}
