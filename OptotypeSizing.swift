import UIKit
import CoreGraphics

struct OptotypeSizing {

    /// Converts logMAR to optotype pixel height (E or Arrow)
    /// - Parameters:
    ///   - logMAR: current stimulus size
    ///   - viewingDistanceMM: distance from eyes to screen in millimeters
    /// - pxPerMM: calibrated pixels per millimeter
    static func pixelHeight(
        logMAR: Double,
        viewingDistanceMM: Double,
        
        pxPerMM: Double
    ) -> CGFloat {

        // 1️⃣ MAR (minutes of arc)
        let mar = pow(10.0, logMAR)

        // 2️⃣ Total optotype height in minutes of arc
        // Tumbling-E and Arrow are BOTH 5 × MAR
        let totalArcMinutes = 5.0 * mar

        // 3️⃣ Convert arc minutes → radians
        let arcRadians = totalArcMinutes * (.pi / (180.0 * 60.0))

        // 4️⃣ Physical height on screen (mm)
        let physicalHeightMM = viewingDistanceMM * tan(arcRadians)

        // 5️⃣ Convert mm → pixels (calibrated)
        let rawPixels = physicalHeightMM * pxPerMM

        // 6️⃣ Safety clamp (prevents absurd sizes)
        let minPixels: Double = 14      // readable minimum
        let maxPixels: Double = 260     // avoids half-screen blobs

        let clampedPixels = min(max(rawPixels, minPixels), maxPixels)
        return CGFloat(clampedPixels)
    }
}
