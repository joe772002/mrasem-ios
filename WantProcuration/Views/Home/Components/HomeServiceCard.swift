//
//  ServiceCard.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//


import SwiftUI
// MARK: -  Service Card
struct HomeServiceCard: View {
    let category: ServiceCategory
    let index: Int
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var appeared = false
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.accentColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: category.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(category.accentColor)
            }
            
            // Texts
            VStack(spacing: 6) {
                Text(category.title)
                    .font(Font.setFontSemiBold(size: 17))
                    .foregroundColor(.theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(category.subtitle)
                    .font(Font.setFontLight(size: 14))
                    .foregroundColor(.theme.themeGray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.theme.white1)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.theme.white1, lineWidth: 1.5)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(category.accentColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 20, y: 10)
        .scaleEffect(appeared ? (isPressed ? 0.95 : 1.0) : 0.8)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                appeared = true
            }
        }
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                action()
            }
        }
        .contentShape(Rectangle())
    }

}

#Preview {
   
    let category = ServiceCategory.previewData.first!
    HomeServiceCard(category: category, index: 0) {}
}
