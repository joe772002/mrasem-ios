//
//  MrasemPreviewsMore.swift
//  Mrasem
//
//  Phase 18 — تكملة MrasemPreviews (B8): رسومات، أيقونات، Chrome، Typography — فاتح وداكن (B5).
//

import SwiftUI

// MARK: - Drawings

private struct MrasemDrawingsSample: View {
    var body: some View {
        MrasemMapPreview(venueLabel: "الوزارة", hotelLabel: "الفندق")

        HStack(spacing: 16) {
            MrasemQrPlaceholder()
            MrasemDressIllustration(kind: .formal, width: 64, height: 80)
            MrasemDressIllustration(kind: .bisht)
        }
    }
}

#Preview("Drawings - Light") {
    MrasemPreview(.light) { MrasemDrawingsSample() }
}

#Preview("Drawings - Dark") {
    MrasemPreview(.dark) { MrasemDrawingsSample() }
}

// MARK: - Icons

private struct MrasemIconsSample: View {
    var body: some View {
        HStack(spacing: 16) {
            MrasemIcons.mission
            MrasemIcons.plan
            MrasemIcons.services
            MrasemIcons.explore
            MrasemIcons.`protocol`
            MrasemIcons.assistant
            MrasemIcons.dash
            MrasemIcons.edit
            MrasemIcons.inbox
        }
        .foregroundStyle(Color.primary)
    }
}

#Preview("Icons - Light") {
    MrasemPreview(.light) { MrasemIconsSample() }
}

#Preview("Icons - Dark") {
    MrasemPreview(.dark) { MrasemIconsSample() }
}

// MARK: - Chrome

private struct MrasemChromeSample: View {
    @State private var roleIndex = 0
    @State private var modeIndex = 0
    @State private var tabIndex = 0

    var body: some View {
        MrasemHeader(
            title: "مراسم",
            subtitle: "MRASEM · وزارة العدل",
            roleOptions: ["الضيف", "فريق المراسم"],
            roleIndex: $roleIndex,
            modeOptions: ["أهلاً بكم في قطر", "مهمة رسمية بالخارج"],
            modeIndex: $modeIndex
        )

        MrasemBottomBar(
            items: [
                MrasemBottomBarItem(label: "المهمة", icon: MrasemIcons.mission),
                MrasemBottomBarItem(label: "البرنامج", icon: MrasemIcons.plan),
                MrasemBottomBarItem(label: "الخدمات", icon: MrasemIcons.services),
                MrasemBottomBarItem(label: "استكشف", icon: MrasemIcons.explore),
                MrasemBottomBarItem(label: "البروتوكول", icon: MrasemIcons.`protocol`),
                MrasemBottomBarItem(label: "المساعد", icon: MrasemIcons.assistant),
            ],
            selectedIndex: $tabIndex
        )
    }
}

#Preview("Chrome - Light") {
    MrasemScreenPreview(.light) { MrasemChromeSample() }
}

#Preview("Chrome - Dark") {
    MrasemScreenPreview(.dark) { MrasemChromeSample() }
}

// MARK: - Typography

private struct MrasemTypographySample: View {
    @Environment(\.mrasem) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("brandTitle — Reem Kufi 700")
                .mrasemText(theme.type.brandTitle)
                .foregroundColor(theme.colors.ink)
            Text("heroDest — Reem Kufi 700")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.ink)
            Text("cardTitle — IBM Plex 700")
                .mrasemText(theme.type.cardTitle)
                .foregroundColor(theme.colors.ink)
            Text("body — IBM Plex 400")
                .mrasemText(theme.type.body)
                .foregroundColor(theme.colors.ink)
            Text("bodySm — IBM Plex 400")
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.ink)
            Text("label — IBM Plex 400")
                .mrasemText(theme.type.label)
                .foregroundColor(theme.colors.muted)
            Text("الأرقام: ١٢٣٤٥٦٧٨٩٠")
                .mrasemText(theme.type.statNumber, tabular: true)
                .foregroundColor(theme.colors.maroonInk)
            Text("brandSub — تباعد 0.08em")
                .mrasemText(theme.type.brandSub)
                .foregroundColor(theme.colors.muted)
        }
    }
}

#Preview("Typography - Light") {
    MrasemPreview(.light) { MrasemTypographySample() }
}

#Preview("Typography - Dark") {
    MrasemPreview(.dark) { MrasemTypographySample() }
}
