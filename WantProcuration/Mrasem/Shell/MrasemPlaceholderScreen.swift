//
//  MrasemPlaceholderScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/shell/MrasemPlaceholderScreen.kt
//

import SwiftUI

/// بديل مؤقت لكل وجهة لحد ما شاشتها الحقيقية تتبني (Phases 4–7).
struct MrasemPlaceholderScreen: View {
    @Environment(\.mrasem) private var theme

    let titleKey: String

    init(titleKey: String = "mrasem_brand_title") {
        self.titleKey = titleKey
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(mrasemString(titleKey))
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)

            Text("mrasem_placeholder_message")
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(theme.colors.bg)
    }
}

#Preview("Placeholder - Light") {
    MrasemScreenPreview(.light) { MrasemPlaceholderScreen(titleKey: "mrasem_tab_mission") }
}

#Preview("Placeholder - Dark") {
    MrasemScreenPreview(.dark) { MrasemPlaceholderScreen(titleKey: "mrasem_tab_mission") }
}
