//
//  EYEVOApp.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/12/26.
//

import SwiftUI

// @main // Disabled duplicate app entry. The real @main lives in EYEVO/EYEVOApp.swift inside the EYEVO folder.
struct EYEVOApp_Disabled: App {

    @State private var showVisionTest = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WelcomeView {
                    showVisionTest = true
                }
                .navigationDestination(isPresented: $showVisionTest) {
                    VisionTestView()
                }
            }
        }
    }
}
