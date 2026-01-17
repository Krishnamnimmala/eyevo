import SwiftUI

struct WelcomeView: View {

    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            Text("Welcome to EYEVO")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("""
This test screens your vision using your phone.
Follow the instructions carefully for best accuracy.
""")
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onStart) {
                Text("Start VISION Test")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
}
