//
//  MrasemActionRow.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemActionRow.kt
//

import SwiftUI

/// صف لوحة الفريق: عنوان Bold + سطر صغير + عنصر في النهاية (زر أو pill).
struct MrasemActionRow<Leading: View>: View {
    @Environment(\.mrasem) private var theme

    let title: String
    let subtitle: String
    @ViewBuilder var leading: () -> Leading

    init(
        title: String,
        subtitle: String,
        @ViewBuilder leading: @escaping () -> Leading
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
    }

    var body: some View {
        let c = theme.colors

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .mrasemText(theme.type.strong)
                    .foregroundColor(c.ink)
                Text(subtitle)
                    .mrasemText(theme.type.label)
                    .foregroundColor(c.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            leading()
        }
        .padding(10)
        .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.serviceRow))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.serviceRow)
                .stroke(c.line, lineWidth: theme.dimens.borderWidth)
        )
    }
}

extension MrasemActionRow where Leading == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}
