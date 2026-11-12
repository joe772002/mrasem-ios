//
//  ActionButton.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import SwiftUI

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let action : () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    )
                
                Text(text)
                    .font(.setFont(size: 14))
                    .foregroundColor(.theme.text)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ActionButton(icon: "bell.fill", text: "Notification", color: Color.theme.accent){
        
    }
}
