//
//  CalibrationStore.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/31/26.
//

import Foundation
import UIKit

@MainActor
final class CalibrationStore {

    static let shared = CalibrationStore()
    private init() {}

    private let keyPxPerMM = "eyevo_px_per_mm"

    /// Pixels per millimeter (PHYSICAL pixels, not points)
    var pxPerMM: Double? {
        let value = UserDefaults.standard.double(forKey: keyPxPerMM)
        return value > 0 ? value : nil
    }

    /// Save calibrated px/mm
    func save(pxPerMM: Double) {
        guard pxPerMM > 1 else {
            assertionFailure("Invalid pxPerMM saved: \(pxPerMM)")
            return
        }

        UserDefaults.standard.set(pxPerMM, forKey: keyPxPerMM)
        debugPrint("[CALIBRATION] Saved pxPerMM =", pxPerMM)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: keyPxPerMM)
    }

    // MARK: - Helper (Use this from Calibration UI)

    /// Convert a measured width in POINTS into calibrated px/mm
    /// - Parameters:
    ///   - measuredWidthPoints: width of credit card measured on screen (SwiftUI geometry)
    ///   - realCardWidthMM: real physical width of the card (e.g., 85.60 mm)
    func computePxPerMM(
        measuredWidthPoints: CGFloat,
        realCardWidthMM: Double = 85.60   // ISO/IEC 7810 ID-1
    ) -> Double {

        let screenScale = UIScreen.main.scale   // 🔑 CRITICAL
        let measuredWidthPixels = Double(measuredWidthPoints) * screenScale

        let pxPerMM = measuredWidthPixels / realCardWidthMM

        debugPrint(
            "[CALIBRATION]",
            "points:", measuredWidthPoints,
            "scale:", screenScale,
            "px/mm:", pxPerMM
        )

        return pxPerMM
    }
}

