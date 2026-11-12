//
//  MrasemSplash.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/shell/MrasemSplash.kt
//

import SwiftUI

/// Phase 0 splash: maroon background with the Mrasem wordmark.
/// Phase 1 switches it to the Reem Kufi display font from the design system.
struct MrasemSplash: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            MrasemBrand.maroon
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Text("mrasem_brand_title")
                    .font(.setFontBold(size: 34))
                    .foregroundColor(MrasemBrand.onHeader)

                Text("mrasem_brand_subtitle")
                    .font(.setFontRegular(size: 15))
                    .foregroundColor(MrasemBrand.onHeader.opacity(0.8))
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

#Preview("Splash") {
    MrasemSplash()
        .environment(\.layoutDirection, .rightToLeft)
}
