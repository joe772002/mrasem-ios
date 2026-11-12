//
//  HomeHeaderCard.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 29/10/2025.
//

import SwiftUI

struct HomeHeaderCard: View {
    var body: some View {
        HStack(spacing: 0) {
            QuickStatItem(
                icon: "clock.fill",
                value: "24/7",
                label: "متاح دائماً",
                color: Color.theme.themeBlue
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.theme.white1.opacity(0.3))
            
            QuickStatItem(
                icon: "shield.checkered",
                value: "آمن",
                label: "موثوق 100%",
                color: Color.theme.themeGreen
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.theme.white1.opacity(0.3))
            
            QuickStatItem(
                icon: "bolt.fill",
                value: "سريع",
                label: "خدمة فورية",
                color: Color.theme.gold
            )
        }
        .padding(.vertical, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        Color.theme.white1.opacity(0.6)
//                        LinearGradient(
//                            gradient: Gradient(colors: [
//                                Color.white.opacity(0.7),
//                                Color.white.opacity(0.4)
//                            ]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.theme.white1.opacity(0.6), lineWidth: 1.5)
            }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        
    }
}
// Quick Stat Item
struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.setFontBold(size: 16))
                .foregroundColor(Color.theme.text)
            
            Text(label)
                .font(.setFontRegular(size: 12))
                .foregroundColor(Color.theme.text)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeHeaderCard()
}
