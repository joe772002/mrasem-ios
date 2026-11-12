//
//  HomeHorizontalServiceCard.swift
//  WantProcuration
//
//  Created by Fatma Informatique on 30/10/2025.
//

import SwiftUI


// Horizontal Service Card: tinted icon tile + title / subtitle
struct HorizontalServiceCard: View {
    @ObservedObject var appManager: AppManager
    let category: ServiceCategory
    let index: Int
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var appeared = false
    
  
    var body: some View {
        HStack(spacing: 14) {
            // Icon: small tinted tile instead of the full-height gradient block
            Image(systemName: category.icon)
                .font(.system(size: 22 * Font.deviceScale, weight: .medium))
                .foregroundStyle(Color.theme.themeBlue)
                .frame(width: 52 * Font.deviceScale, height: 52 * Font.deviceScale)
                .background(Color.theme.themeBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(Font.setFontSemiBold(size: 17))
                    .foregroundColor(.theme.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(category.subtitle)
                    .font(Font.setFontRegular(size: 13))
                    .foregroundColor(.theme.themeGray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.forward")
                .font(.system(size: 14 * Font.deviceScale, weight: .semibold))
                .foregroundStyle(Color.theme.themeGray.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 84)
        .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                action()
            }
        }
    }
}

#Preview {
    let appManager = AppManager()
    let category = ServiceCategory.previewData.first!
    HorizontalServiceCard(appManager: appManager, category: category, index: 0){}
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)

}
