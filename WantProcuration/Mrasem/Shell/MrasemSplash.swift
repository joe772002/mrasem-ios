//
//  MrasemSplash.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/shell/MrasemSplash.kt
//

import SwiftUI

/// سبلاش مراسم: خلفية عنّابية مع اسم التطبيق.
struct MrasemSplash: View {
    @Environment(\.mrasem) private var theme
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            theme.colors.headerBg
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Text("mrasem_brand_title")
                    .mrasemText(theme.type.brandTitle)
                    .foregroundColor(theme.colors.onHeader)

                Text("mrasem_brand_subtitle")
                    .mrasemText(theme.type.brandSub)
                    .foregroundColor(theme.colors.onHeader.opacity(0.8))
            }
            .opacity(progress)
            .scaleEffect(0.9 + 0.1 * progress)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                progress = 1
            }
        }
    }
}

#Preview("Splash - Light") {
    MrasemSplash()
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Splash - Dark") {
    MrasemSplash()
        .mrasemTheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}
