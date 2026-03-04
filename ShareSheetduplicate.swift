//
//  ShareSheet.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 2/3/26.
//

import SwiftUI
import UIKit



    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
