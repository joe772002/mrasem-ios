//
//  InfoRow.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//


import SwiftUI
// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    /// Tappable row (e.g. directions): blue underlined value + arrow, so it reads as a link.
    var isLink: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Label small and grey, value bold: the eye goes to the information first.
                Text(title)
                    .font(.setFontRegular(size: 13))
                    .foregroundColor(.theme.secondaryText2)
                Text(value)
                    .font(.setFontSemiBold(size: 15))
                    .foregroundColor(isLink ? .theme.themeBlue : .theme.text)
                    .underline(isLink, color: .theme.themeBlue.opacity(0.5))
            }
            
            Spacer()

        }
        .contentShape(Rectangle())
    }
}
