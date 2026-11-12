//
//  MrasemPlaceholderScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/shell/MrasemPlaceholderScreen.kt
//

import SwiftUI

/// Phase 0 start destination. Replaced by MrasemShell in Phase 3.
struct MrasemPlaceholderScreen: View {
    @Environment(\.mrasem) private var theme

    var body: some View {
        VStack(spacing: 8) {
            Text("mrasem_brand_title")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)

            Text("mrasem_placeholder_message")
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(theme.colors.bg.ignoresSafeArea())
    }
}

#Preview("Placeholder - Light") {
    MrasemPlaceholderScreen()
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Placeholder - Dark") {
    MrasemPlaceholderScreen()
        .mrasemTheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}
