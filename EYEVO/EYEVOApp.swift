import SwiftUI

@main
struct EYEVOApp: App {

    @State private var showTest = false
    @State private var useQuest = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if showTest {
                    VisionTestView(useQuest: useQuest)
                } else {
                    WelcomeView { selectedQuest in
                        useQuest = selectedQuest
                        showTest = true
                    }
                }
            }
            .onAppear {
                #if DEBUG
                runDebugEngineTests()
                #endif
            }
        }
    }
}
