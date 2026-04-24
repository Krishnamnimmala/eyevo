import UIKit
import CoreGraphics

struct OptotypeSizing {

    /// Converts logMAR to optotype pixel height
    /// - Parameters:
    ///   - logMAR: Current stimulus size in logMAR
    ///   - viewingDistanceMM: Distance from eyes to screen in millimeters
    ///   - pxPerMM: Calibrated pixels per millimeter
    ///   - optotype: Current optotype type (arrows or Landolt-C)
    static func pixelHeight(
        logMAR: Double,
        viewingDistanceMM: Double,
        pxPerMM: Double,
        optotype: Stimulus.Optotype
    ) -> CGFloat {

        // 1) MAR (minutes of arc)
        let mar = pow(10.0, logMAR)

        // 2) Total optotype height in arc minutes
        let totalArcMinutes = 5.0 * mar

        // 3) Convert arc minutes -> radians
        let arcRadians = totalArcMinutes * (.pi / (180.0 * 60.0))

        // 4) Physical height on screen (mm)
        let physicalHeightMM = viewingDistanceMM * tan(arcRadians)

        // 5) Convert mm -> pixels using calibrated px/mm
        let rawPixels = physicalHeightMM * pxPerMM

        // 6) Optotype-specific minimum clamp
        // Keep arrows readable, and keep Landolt-C stable at the hard end.
        let minPixels: Double = {
            switch optotype {
            case .arrows:
                return 18.0

            case .landoltC:
                return 14.0
            }
        }()

        // 7) Safety maximum
        let maxPixels: Double = 260.0

        // 8) Clamp
        let clampedPixels = min(max(rawPixels, minPixels), maxPixels)

        print("""
        [OPTOTYPE SIZING]
        logMAR: \(logMAR)
        viewingDistanceMM: \(viewingDistanceMM)
        pxPerMM: \(pxPerMM)
        optotype: \(optotype)
        mar: \(mar)
        physicalHeightMM: \(physicalHeightMM)
        rawPixels: \(rawPixels)
        minPixels: \(minPixels)
        maxPixels: \(maxPixels)
        clampedPixels: \(clampedPixels)
        """)

        return CGFloat(clampedPixels)
    }
}
