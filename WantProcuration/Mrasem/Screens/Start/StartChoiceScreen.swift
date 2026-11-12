//
//  StartChoiceScreen.swift
//  Mrasem
//
//  Phase 13 — أول تشغيل: «ابدأ فارغ» أو «حمّل بيانات العرض» (08 §3). مفيش بيانات افتراضية مفروضة.
//

import SwiftUI

struct StartChoiceScreen: View {
    @Environment(\.mrasem) private var theme

    private let flow: MrasemAppFlow

    init(context: MrasemAppContext) {
        self.flow = context.flow
    }

    var body: some View {
        let c = theme.colors

        ScrollView {
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("mrasem_brand_title")
                        .mrasemText(theme.type.heroDest)
                        .foregroundColor(c.maroon)
                        .accessibilityAddTraits(.isHeader)
                    Text("mrasem_start_title")
                        .mrasemText(theme.type.cardTitle)
                        .foregroundColor(c.ink)
                }

                Text("mrasem_start_message")
                    .mrasemText(theme.type.bodySm)
                    .foregroundColor(c.muted)

                choice(
                    title: mrasemString("mrasem_start_demo"),
                    hint: mrasemString("mrasem_start_demo_hint"),
                    variant: .primary
                ) { flow.startChosen(demo: true) }

                choice(
                    title: mrasemString("mrasem_start_empty"),
                    hint: mrasemString("mrasem_start_empty_hint"),
                    variant: .secondary
                ) { flow.startChosen(demo: false) }

                Text("mrasem_start_footer")
                    .mrasemText(theme.type.label)
                    .foregroundColor(c.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, theme.dimens.screenHorizontal)
            .padding(.vertical, theme.dimens.screenTop)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(c.bg.ignoresSafeArea())
    }

    private func choice(title: String, hint: String, variant: ButtonVariant, action: @escaping () -> Void) -> some View {
        MrasemCard {
            Text(hint)
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.ink)
            MrasemButton(title, variant: variant, block: true, action: action)
        }
    }
}

#Preview("Start - Light") {
    StartChoiceScreen(context: .preview())
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Start - Dark") {
    StartChoiceScreen(context: .preview())
        .mrasemTheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}
