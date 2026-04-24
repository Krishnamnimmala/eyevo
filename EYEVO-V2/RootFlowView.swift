//
//  RootFlowView.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/31/26.
//

import SwiftUI

struct RootFlowView: View {

    enum FlowStep {
        case calibration
        case welcome
        case test
    }

    @State private var step: FlowStep = .welcome

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                currentStepView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {

        case .calibration:
            EyevoCalibrationView {
                step = .welcome
            }

        case .welcome:
            WelcomeView {
                if CalibrationStore.shared.pxPerMM == nil {
                    step = .calibration
                } else {
                    step = .test
                }
            }

        case .test:
            VisionTestView {
                step = .welcome
            }
        }
    }

    private var backgroundColor: Color {
        switch step {
        case .test:
            return .black
        case .calibration, .welcome:
            return Color(.systemBackground)
        }
    }
}
