//
//  AssistantFloatingButton.swift
//  WantProcuration
//
//  Floating "مساعد التوثيق" button shown at the bottom corner of the Home screen.
//

import SwiftUI

struct AssistantFloatingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("service_assistant".localized())
                    .font(.setFontSemiBold(size: 15))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(Color.theme.themeBlue, in: Capsule())
            .shadow(color: Color.theme.themeBlue.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(FloatingPressStyle())
        .accessibilityLabel("service_assistant".localized())
        .accessibilityHint("service_assistant_desc".localized())
    }
}

private struct FloatingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
