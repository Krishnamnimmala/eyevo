import SwiftUI

@main
struct EYEVOApp: App {

    @State private var showTest = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if showTest {
                    VisionTestView()
                } else {
                    WelcomeView {
                        showTest = true
                    }
                }
            }
            .onAppear {
                // Disabled automatic in-app debug runner to avoid build-time test invocation
                // Debug test harness is available under Tools/engine_test_runner.swift and
                // can be run separately for deterministic testing.
            }
        }
    }
}

#if DEBUG

// NOTE: The inline runDebugEngineTests() was moved out of the app startup to avoid
// build-time invocation. If you want to run lightweight engine checks during debug,
// use the standalone runner at Tools/engine_test_runner.swift or call the helper in
// a debug-only environment manually.

#endif
