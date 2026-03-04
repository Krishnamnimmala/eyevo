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

        VStack(spacing: 0) {

            // Main flow switch
            switch step {

            case .calibration:
                CreditCardCalibrationView {
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
                    // 🔑 THIS IS WHAT EXIT TRIGGERS
                    step = .welcome
                }
            }
        }
    }
}

