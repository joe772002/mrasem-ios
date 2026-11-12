//
//  MrasemListItemsMore.swift
//  Mrasem
//
//  Phase 18 — تكملة MrasemListItems (B8): بطاقة المكان، بانر التنبيه، صف القائمة، فقاعة المحادثة، والـ FlowLayout.
//

import SwiftUI

/// بطاقة مكان (.place في المصدر): الاسم + pill + الوصف + سطر الميتا + الزر.
struct MrasemPlaceCard: View {
    @Environment(\.mrasem) private var theme

    let name: String
    let tag: String?
    let description: String
    let meta: [String]
    let actionLabel: String
    let actionEnabled: Bool
    let onAction: () -> Void

    init(
        name: String,
        tag: String?,
        description: String,
        meta: [String],
        actionLabel: String,
        actionEnabled: Bool = true,
        onAction: @escaping () -> Void = {}
    ) {
        self.name = name
        self.tag = tag
        self.description = description
        self.meta = meta
        self.actionLabel = actionLabel
        self.actionEnabled = actionEnabled
        self.onAction = onAction
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(name)
                    .mrasemText(theme.type.cardTitle)
                    .foregroundColor(c.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let tag {
                    MrasemPill(tag)
                }
            }

            Text(description)
                .mrasemText(theme.type.bodySm)
                .foregroundColor(c.ink)

            HStack(spacing: 10) {
                ForEach(meta, id: \.self) { item in
                    Text(item)
                        .mrasemText(theme.type.label)
                        .foregroundColor(c.muted)
                }
            }

            MrasemButton(
                actionLabel,
                variant: actionEnabled ? .primary : .secondary,
                block: true,
                enabled: actionEnabled,
                action: onAction
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.place))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.place)
                .stroke(c.line, lineWidth: theme.dimens.borderWidth)
        )
    }
}

struct MrasemNoticeBanner: View {
    @Environment(\.mrasem) private var theme

    let title: String
    /// اسمها `message` مش `body` عشان ما تتعارضش مع `View.body`.
    let message: String

    init(title: String, body: String) {
        self.title = title
        self.message = body
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .mrasemText(theme.type.strong)
                .foregroundColor(c.ink)
            Text(message)
                .mrasemText(theme.type.bodySm)
                .foregroundColor(c.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(c.noticeBg, in: RoundedRectangle(cornerRadius: theme.shapes.notice))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.notice)
                .stroke(c.noticeBorder, lineWidth: theme.dimens.borderWidth)
        )
    }
}

struct MrasemChecklistRow: View {
    @Environment(\.mrasem) private var theme

    let text: String
    let checked: Bool
    let onToggle: () -> Void

    init(text: String, checked: Bool, onToggle: @escaping () -> Void = {}) {
        self.text = text
        self.checked = checked
        self.onToggle = onToggle
    }

    var body: some View {
        let c = theme.colors

        HStack(spacing: 10) {
            MrasemCheckbox(checked: checked)
                .frame(width: 22, height: 22)

            Text(text)
                .mrasemText(theme.type.bodySm)
                .foregroundColor(checked ? c.muted : c.ink)
        }
        .frame(maxWidth: .infinity, minHeight: theme.dimens.minTouch, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(text)
        .accessibilityAddTraits(checked ? [.isSelected] : [])
    }
}

/// مربع اختيار مع علامة صح.
private struct MrasemCheckbox: View {
    @Environment(\.mrasem) private var theme

    let checked: Bool

    var body: some View {
        let c = theme.colors

        ZStack {
            RoundedRectangle(cornerRadius: theme.shapes.stat)
                .fill(checked ? c.maroon : c.surface)
            RoundedRectangle(cornerRadius: theme.shapes.stat)
                .stroke(checked ? c.maroon : c.line, lineWidth: 2)

            if checked {
                MrasemCheckMark()
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .foregroundColor(c.onMaroon)
                    .padding(4)
            }
        }
    }
}

/// علامة الصح (صحّ).
private struct MrasemCheckMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.move(to: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + w * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.43, y: rect.minY + w * 0.70))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + w * 0.32))
        return path
    }
}

/// فقاعة محادثة: رد المساعد بسطح وحدّ خط، ورسالة المستخدم بخلفية العنّابي.
struct MrasemChatBubble: View {
    @Environment(\.mrasem) private var theme

    let text: String
    let fromMe: Bool

    init(text: String, fromMe: Bool) {
        self.text = text
        self.fromMe = fromMe
    }

    var body: some View {
        let c = theme.colors

        HStack {
            if fromMe { Spacer(minLength: 0) }

            Text(text)
                .mrasemText(theme.type.bodySm)
                .foregroundColor(fromMe ? c.onMaroon : c.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(fromMe ? c.maroon : c.surface, in: fromMe ? theme.shapes.bubbleMe() : theme.shapes.bubbleBot())
                .overlay {
                    if !fromMe {
                        theme.shapes.bubbleBot()
                            .stroke(c.line, lineWidth: theme.dimens.borderWidth)
                    }
                }

            if !fromMe { Spacer(minLength: 0) }
        }
    }
}

/// تخطيط بيلف العناصر زي `FlowRow` في Compose.
struct MrasemFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 4

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                totalWidth = max(totalWidth, x - spacing)
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = max(totalHeight, y + lineHeight)
        }

        totalWidth = max(totalWidth, x - spacing)
        return CGSize(
            width: maxWidth.isFinite ? maxWidth : totalWidth,
            height: totalHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
