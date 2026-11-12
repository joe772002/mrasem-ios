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

    /// لو اتغيّرت القيمة دي الشاشة بتتمرّر لآخرها (زي `animateScrollTo(maxValue)` في Android).
    let scrollToEndTrigger: Int?
    var content: () -> Content

    init(scrollToEndTrigger: Int? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.scrollToEndTrigger = scrollToEndTrigger
        self.content = content
    }

    var body: some View {
        ScrollViewReader { proxy in
          ScrollView {
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                content()
                MrasemDemoFooter()
                Color.clear.frame(height: 0).id(Self.endAnchor)
            }
            .padding(.horizontal, theme.dimens.screenHorizontal)
            .padding(.top, theme.dimens.screenTop)
            .padding(.bottom, theme.dimens.screenTop)
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .background(theme.colors.bg)
          .onChange(of: scrollToEndTrigger) { _, _ in
              guard scrollToEndTrigger != nil else { return }
              withAnimation { proxy.scrollTo(Self.endAnchor, anchor: .bottom) }
          }
        }
    }

    private static var endAnchor: String { "mrasem_screen_end" }
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
