import SwiftUI

struct WelcomeView: View {

    let onStart: () -> Void

    var body: some View {

        NavigationStack {

            VStack(spacing: 28) {

                Spacer()

                // MARK: - App Title
                Text("EYEVO")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // MARK: - Tagline
                Text("Quick smartphone vision screening")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // MARK: - Privacy Statement
                Text("Device-stored results — your privacy first")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // MARK: - Primary Action
                Button {
                    onStart()
                } label: {
                    Text("Start Screening")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // MARK: - Secondary Action
                NavigationLink {
                    ResultsHistoryView()
                } label: {
                    Text("View Results")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Spacer()
            }
            .padding()
        }
    }
}

