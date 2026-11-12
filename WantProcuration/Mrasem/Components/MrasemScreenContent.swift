//
//  MrasemScreenContent.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemScreenContent.kt
//

import SwiftUI

/// محتوى أي تاب: scroll + padding الشاشة + فاصل بين الأقسام،
/// وفي الآخر سطر «بيانات توضيحية لنموذج أولي.».
struct MrasemScreenContent<Content: View>: View {
    @Environment(\.mrasem) private var theme

    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                content()
                MrasemDemoFooter()
            }
            .padding(.horizontal, theme.dimens.screenHorizontal)
            .padding(.top, theme.dimens.screenTop)
            .padding(.bottom, theme.dimens.screenTop)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.bg)
    }
}

struct MrasemDemoFooter: View {
    @Environment(\.mrasem) private var theme

    var body: some View {
        Text("mrasem_demo_footer")
            .mrasemText(theme.type.label)
            .foregroundColor(theme.colors.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
