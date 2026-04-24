//
//  ShareSheet.swfit
//  EYEVO
//
//  Created by Krishnam Nimmala on 2/16/26.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
