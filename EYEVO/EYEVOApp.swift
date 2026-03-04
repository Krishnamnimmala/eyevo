import SwiftUI

@main
struct EYEVOApp: App {

    private enum AppFlow {
        case welcome
        case distanceGate
        case visionTest
    }

    @State private var flow: AppFlow = .welcome

    var body: some Scene {
        WindowGroup {
            RootFlowView()
        }

    }

    @ViewBuilder
    private var rootView: some View {
        switch flow {

        case .welcome:
            WelcomeView {
                flow = .distanceGate
            }

        case .distanceGate:
            DistanceEnforcementView(
                currentEye: .left,
                onContinue: {},
                onBack: {}
            )


        case .visionTest:
            VisionTestView(
                onExit: {
                    flow = .welcome
                }
            )
        }
    }
}
