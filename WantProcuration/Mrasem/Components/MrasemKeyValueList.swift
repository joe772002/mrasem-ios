//
//  MrasemKeyValueList.swift
//  Mrasem
//
//  Phase 18 — من MrasemCards (B8): قائمة «مفتاح: قيمة» وتخطيطها.
//

import SwiftUI

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
