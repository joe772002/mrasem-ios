//
//  MrasemCards.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemCards.kt
//

import SwiftUI

/// كارت عادي: خلفية surface + حد line + عنوان اختياري.
struct MrasemCard<Content: View>: View {
    @Environment(\.mrasem) private var theme

    let title: String?
    let headerEnd: AnyView?
    @ViewBuilder var content: () -> Content

    init(
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.headerEnd = nil
        self.content = content
    }

    init(
        title: String? = nil,
        headerEnd: AnyView,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.headerEnd = headerEnd
        self.content = content
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: theme.dimens.cardGap) {
            if title != nil || headerEnd != nil {
                HStack(alignment: .center, spacing: 8) {
                    if let title {
                        Text(title)
                            .mrasemText(theme.type.cardHeader)
                            .foregroundColor(c.muted)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Spacer(minLength: 0)
                    headerEnd
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.dimens.cardPadding)
        .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.card))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.card)
                .stroke(c.line, lineWidth: theme.dimens.borderWidth)
        )
    }
}

/// كارت البطل: حد علوي عنّابي 4pt.
struct MrasemHeroCard<Content: View>: View {
    @Environment(\.mrasem) private var theme

    @ViewBuilder var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(c.maroon)
                .frame(height: theme.dimens.heroTopBorder)

            VStack(alignment: .leading, spacing: theme.dimens.heroGap) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.dimens.heroPadding)
        }
        .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.hero))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.hero)
                .stroke(c.line, lineWidth: theme.dimens.borderWidth)
        )
    }
}

enum PillKind {
    case neutral
    case ok
    case warn
}

struct MrasemPill: View {
    @Environment(\.mrasem) private var theme

    let text: String
    let kind: PillKind

    init(_ text: String, kind: PillKind = .neutral) {
        self.text = text
        self.kind = kind
    }

    var body: some View {
        let c = theme.colors
        let background: Color
        let foreground: Color

        switch kind {
        case .neutral:
            background = c.tint
            foreground = c.maroonInk
        case .ok:
            background = c.pillOkBg
            foreground = c.ok
        case .warn:
            background = c.pillWarnBg
            foreground = c.warn
        }

        Text(text)
            .mrasemText(theme.type.pill)
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(background, in: RoundedRectangle(cornerRadius: theme.shapes.pill))
    }
}

struct MrasemStatTile: View {
    @Environment(\.mrasem) private var theme

    let value: String
    let label: String

    init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    var body: some View {
        let c = theme.colors

        VStack(spacing: 2) {
            Text(value)
                .mrasemText(theme.type.statNumber, tabular: true)
                .foregroundColor(c.maroonInk)
            Text(label)
                .mrasemText(theme.type.caption)
                .foregroundColor(c.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(c.tint, in: RoundedRectangle(cornerRadius: theme.shapes.stat))
    }
}

struct MrasemKpiTile: View {
    @Environment(\.mrasem) private var theme

    let value: String
    let label: String

    init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    var body: some View {
        let c = theme.colors

        VStack(spacing: 2) {
            Text(value)
                .mrasemText(theme.type.kpiNumber, tabular: true)
                .foregroundColor(c.ink)
            Text(label)
                .mrasemText(theme.type.caption)
                .foregroundColor(c.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.kpi))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.kpi)
                .stroke(c.line, lineWidth: theme.dimens.borderWidth)
        )
    }
}

/// صف مفتاح/قيمة.
struct KeyValue: Identifiable {
    let key: String
    let value: String
    /// للقيم اللاتينية (هواتف، أرقام) — قاعدة B6.
    let ltr: Bool

    var id: String { key + "|" + value }

    init(_ key: String, _ value: String, ltr: Bool = false) {
        self.key = key
        self.value = value
        self.ltr = ltr
    }
}

/// قائمة مفتاح/قيمة: عمود المفتاح بعرض أعرض مفتاح والقيمة تاخد الباقي.
struct MrasemKeyValueList: View {
    @Environment(\.mrasem) private var theme

    let items: [KeyValue]

    init(_ items: [KeyValue]) {
        self.items = items
    }

    var body: some View {
        let c = theme.colors

        MrasemKeyValueLayout {
            ForEach(items) { item in
                Text(item.key)
                    .mrasemText(theme.type.bodySm)
                    .foregroundColor(c.muted)

                Group {
                    Text(item.value)
                        .mrasemText(theme.type.bodySm)
                        .foregroundColor(c.ink)
                        .fontWeight(.medium)
                }
                .environment(\.layoutDirection, item.ltr ? .leftToRight : .rightToLeft)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// تخطيط عمودين: عمود المفتاح بعرض أعرض مفتاح (بحد أقصى نص العرض)، والقيمة تاخد الباقي.
private struct MrasemKeyValueLayout: Layout {
    var gapX: CGFloat = 12
    var gapY: CGFloat = 4
    var maxKeyRatio: CGFloat = 0.5

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        guard maxWidth > 0 else { return .zero }

        let keyWidth = keyColumnWidth(subviews: subviews, maxWidth: maxWidth)
        let valueWidth = max(0, maxWidth - keyWidth - gapX)
        let heights = rowHeights(subviews: subviews, keyWidth: keyWidth, valueWidth: valueWidth)
        let height = heights.reduce(0, +) + gapY * CGFloat(max(0, heights.count - 1))

        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let keyWidth = keyColumnWidth(subviews: subviews, maxWidth: bounds.width)
        let valueWidth = max(0, bounds.width - keyWidth - gapX)
        let heights = rowHeights(subviews: subviews, keyWidth: keyWidth, valueWidth: valueWidth)

        var y = bounds.minY
        for (index, height) in heights.enumerated() {
            if index * 2 < subviews.count {
                subviews[index * 2].place(
                    at: CGPoint(x: bounds.minX, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: keyWidth, height: height)
                )
            }
            if index * 2 + 1 < subviews.count {
                subviews[index * 2 + 1].place(
                    at: CGPoint(x: bounds.minX + keyWidth + gapX, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: valueWidth, height: height)
                )
            }
            y += height + gapY
        }
    }

    private func keyColumnWidth(subviews: Subviews, maxWidth: CGFloat) -> CGFloat {
        let limit = maxWidth * maxKeyRatio
        var widest: CGFloat = 0
        var index = 0
        for subview in subviews {
            if index % 2 == 0 {
                let size = subview.sizeThatFits(.unspecified)
                widest = max(widest, size.width)
            }
            index += 1
        }
        return min(widest, limit)
    }

    private func rowHeights(subviews: Subviews, keyWidth: CGFloat, valueWidth: CGFloat) -> [CGFloat] {
        var heights: [CGFloat] = []
        var index = 0
        while index + 1 < subviews.count {
            let keyHeight = subviews[index].sizeThatFits(
                ProposedViewSize(width: keyWidth, height: nil)
            ).height
            let valueHeight = subviews[index + 1].sizeThatFits(
                ProposedViewSize(width: valueWidth, height: nil)
            ).height
            heights.append(max(keyHeight, valueHeight))
            index += 2
        }
        return heights
    }
}
