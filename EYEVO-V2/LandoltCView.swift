import SwiftUI

struct LandoltCView: View {
    let openingDirection: ResponseDirection
    let size: CGFloat
    let gapAngle: Double
    let ringThicknessRatio: CGFloat

    init(
        openingDirection: ResponseDirection,
        size: CGFloat,
        gapAngle: Double = 20,
        ringThicknessRatio: CGFloat = 0.22
    ) {
        self.openingDirection = openingDirection
        self.size = size
        self.gapAngle = gapAngle
        self.ringThicknessRatio = ringThicknessRatio
    }

    var body: some View {
        LandoltCShape(
            openingDirection: openingDirection,
            gapAngle: gapAngle,
            ringThicknessRatio: ringThicknessRatio
        )
        .fill(Color.white, style: FillStyle(eoFill: true))
        .frame(width: size, height: size)
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            LandoltCView(openingDirection: .up, size: 80)
            LandoltCView(openingDirection: .right, size: 80)
            LandoltCView(openingDirection: .downLeft, size: 80)
        }
    }
}
