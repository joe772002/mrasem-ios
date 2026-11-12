//
//  MrasemPreview.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemPreview.kt
//

import SwiftUI

/// غلاف موحّد للـ Previews: RTL + ثيم مراسم.
struct MrasemPreview<Content: View>: View {
    @Environment(\.mrasem) private var theme

    let option: MrasemThemeOption
    let padding: CGFloat
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(
        _ option: MrasemThemeOption = .light,
        padding: CGFloat = 16,
        spacing: CGFloat = 12,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.option = option
        self.padding = padding
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(theme.colors.bg)
        .environment(\.layoutDirection, .rightToLeft)
        .mrasemTheme(option)
    }
}

/// غلاف previews الشاشات الكاملة: RTL + ثيم مراسم + خلفية التطبيق (من غير padding إضافي).
struct MrasemScreenPreview<Content: View>: View {
    @Environment(\.mrasem) private var theme

    let option: MrasemThemeOption
    @ViewBuilder var content: () -> Content

    init(
        _ option: MrasemThemeOption = .light,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.option = option
        self.content = content
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(theme.colors.bg)
            .environment(\.layoutDirection, .rightToLeft)
            .mrasemTheme(option)
    }
}
