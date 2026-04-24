//
//  NotSureButton.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 4/5/26.
//

import SwiftUI

struct NotSureButton: View {
    let enabled: Bool
    let isCompact: Bool
    let action: () -> Void

    private let orangePrimary = Color.orange
    private let orangeFillTop = Color(red: 0.28, green: 0.14, blue: 0.00)
    private let orangeFillBottom = Color(red: 0.18, green: 0.08, blue: 0.00)

    var body: some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: isCompact ? 20 : 22, weight: .semibold))

                Text("Not Sure")
                    .font(isCompact ? .title3 : .title2)
                    .fontWeight(.bold)
                    .tracking(0.2)
            }
            .foregroundStyle(enabled ? orangePrimary : Color.gray)
            .frame(maxWidth: .infinity)
            .frame(height: isCompact ? 78 : 84)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 24 : 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: enabled
                            ? [orangeFillTop, orangeFillBottom]
                            : [Color.gray.opacity(0.20), Color.gray.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 24 : 26, style: .continuous)
                    .stroke(
                        enabled
                        ? orangePrimary.opacity(0.35)
                        : Color.gray.opacity(0.20),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: enabled ? orangePrimary.opacity(0.12) : .clear, radius: 6, x: 0, y: 0)
            .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 3)
            .opacity(enabled ? 1.0 : 0.60)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel("Not Sure")
        .accessibilityHint("Use this if you are unsure about the symbol direction")
    }
}

#Preview("Not Sure Enabled") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            NotSureButton(
                enabled: true,
                isCompact: true,
                action: { }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

#Preview("Not Sure Disabled") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            NotSureButton(
                enabled: false,
                isCompact: true,
                action: { }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}
