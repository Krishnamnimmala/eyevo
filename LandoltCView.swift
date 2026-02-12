import SwiftUI

struct LandoltCView: View {

    let openingDirection: ResponseDirection
    let size: CGFloat

    private var stroke: CGFloat {
        max(1.0, size * 0.11)
    }

    private var gap: CGFloat {
        max(1.0, stroke * 0.45)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: stroke)
                .frame(width: size, height: size)

            Rectangle()
                .fill(Color.black)
                .frame(width: gap, height: gapDepth)
                .offset(gapOffset)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .accessibilityHidden(true)
    }

    private var gapDepth: CGFloat {
        max(stroke * 0.65, 2.5)
    }

    private var gapOffset: CGSize {
        let r = size / 2.0
        let edge = r - (stroke / 2.0)

        switch openingDirection {
        case .up:    return CGSize(width: 0,     height: -edge)
        case .down:  return CGSize(width: 0,     height: edge)
        case .left:  return CGSize(width: -edge, height: 0)
        case .right: return CGSize(width: edge,  height: 0)
        }
    }
}
