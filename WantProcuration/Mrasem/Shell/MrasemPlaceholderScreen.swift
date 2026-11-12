//
//  MrasemPlaceholderScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/shell/MrasemPlaceholderScreen.kt
//

import SwiftUI
import UIKit

/// Phase 0 start destination. Replaced by MrasemShell in Phase 3.
struct MrasemPlaceholderScreen: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("mrasem_brand_title")
                .font(.setFontBold(size: 28))
                .foregroundColor(MrasemBrand.maroon)

            Text("mrasem_placeholder_message")
                .font(.setFontRegular(size: 16))
                .foregroundColor(Color.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}

#Preview("Placeholder") {
    MrasemPlaceholderScreen()
        .environment(\.layoutDirection, .rightToLeft)
}
