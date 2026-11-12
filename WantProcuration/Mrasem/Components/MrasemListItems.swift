//
//  MrasemListItems.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemListItems.kt
//

import SwiftUI

/// خطوات الحالة. `current` = عدد الخطوات المنجزة (الخطوة الحالية = current).
struct MrasemStatusSteps: View {
    @Environment(\.mrasem) private var theme

    let steps: [String]
    let current: Int

    init(steps: [String], current: Int) {
        self.steps = steps
        self.current = current
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                let isDone = current > index
                let isNow = current == index
                let dotColor = isDone ? c.ok : (isNow ? c.gold : c.line)

                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(isDone ? c.ok : (isNow ? c.gold : Color.clear))
                        .frame(width: 12, height: 12)
                        .overlay {
                            Circle().stroke(dotColor, lineWidth: 2)
                        }
                        .padding(.top, 6)

                    Text(text)
                        .mrasemText(theme.type.bodySm)
                        .foregroundColor(c.ink)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// فقرة رسمية في الـ timeline.
struct MrasemTimelineItem: View {
    @Environment(\.mrasem) private var theme

    let time: String
    let title: String
    let place: String
    let note: String?
    let changed: Bool
    let changedLabel: String
    let keyCardLabel: String?
    let onKeyCardClick: () -> Void
    let showDivider: Bool

    init(
        time: String,
        title: String,
        place: String,
        note: String? = nil,
        changed: Bool = false,
        changedLabel: String = "",
        keyCardLabel: String? = nil,
        onKeyCardClick: @escaping () -> Void = {},
        showDivider: Bool = true
    ) {
        self.time = time
        self.title = title
        self.place = place
        self.note = note
        self.changed = changed
        self.changedLabel = changedLabel
        self.keyCardLabel = keyCardLabel
        self.onKeyCardClick = onKeyCardClick
        self.showDivider = showDivider
    }

    var body: some View {
        let c = theme.colors

        HStack(alignment: .top, spacing: 10) {
            Text(time)
                .mrasemText(theme.type.time, tabular: true)
                .foregroundColor(c.maroonInk)
                .frame(width: 58, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                // العنوان والـ pill في سطر واحد لو اتّسعوا.
                MrasemFlowLayout(spacing: 8) {
                    titleText
                    if changed { changedPill }
                }

                Text(place)
                    .mrasemText(theme.type.label)
                    .foregroundColor(c.muted)

                if let note {
                    Text(note)
                        .mrasemText(theme.type.label)
                        .foregroundColor(c.muted)
                }

                if let keyCardLabel {
                    MrasemChip(keyCardLabel, action: onKeyCardClick)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, changed ? 8 : 0)
        .padding(.vertical, 10)
        .background(
            changed ? c.timelineChangedBg : Color.clear,
            in: RoundedRectangle(cornerRadius: changed ? 8 : 0)
        )
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle()
                    .fill(c.line)
                    .frame(height: theme.dimens.borderWidth)
            }
        }
    }

    private var titleText: some View {
        Text(title)
            .mrasemText(theme.type.strong)
            .foregroundColor(theme.colors.ink)
    }

    private var changedPill: some View {
        MrasemPill(changedLabel, kind: .warn)
    }
}

/// فقرة «وقت حر»: حد ذهبي متقطع + وقت البداية + اقتراحات.
struct MrasemFreeTimeItem: View {
    @Environment(\.mrasem) private var theme

    let from: String
    let title: String
    let description: String
    let suggestions: [String]
    let onSuggestion: (String) -> Void

    init(
        from: String,
        title: String,
        description: String,
        suggestions: [String],
        onSuggestion: @escaping (String) -> Void = { _ in }
    ) {
        self.from = from
        self.title = title
        self.description = description
        self.suggestions = suggestions
        self.onSuggestion = onSuggestion
    }

    var body: some View {
        let c = theme.colors

        HStack(alignment: .top, spacing: 10) {
            Text(from)
                .mrasemText(theme.type.time, tabular: true)
                .foregroundColor(c.maroonInk)
                .frame(width: 58, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .mrasemText(theme.type.strong)
                    .foregroundColor(c.ink)
                Text(description)
                    .mrasemText(theme.type.label)
                    .foregroundColor(c.muted)

                if !suggestions.isEmpty {
                    // chips بتلتف — بنستخدم FlowLayout (iOS 16+).
                    MrasemFlowLayout(spacing: 6) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            MrasemChip(suggestion) { onSuggestion(suggestion) }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(c.gold, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        )
    }
}

/// صف خدمة: شعار ملوّن + اسم عربي + اسم إنجليزي + وصف + زر «فتح».
struct MrasemServiceRow: View {
    @Environment(\.mrasem) private var theme

    let name: String
    let nameEn: String?
    let description: String
    let logoText: String
    let logoColor: Color
    let actionLabel: String?
    let onClick: () -> Void

    init(
        name: String,
        nameEn: String? = nil,
        description: String,
        logoText: String,
        logoColor: Color,
        actionLabel: String? = nil,
        onClick: @escaping () -> Void = {}
    ) {
        self.name = name
        self.nameEn = nameEn
        self.description = description
        self.logoText = logoText
        self.logoColor = logoColor
        self.actionLabel = actionLabel
        self.onClick = onClick
    }

    var body: some View {
        let c = theme.colors

        HStack(spacing: 12) {
            Text(logoText)
                .mrasemText(theme.type.strong)
                .foregroundColor(c.onMaroon)
                .frame(width: theme.dimens.serviceLogo, height: theme.dimens.serviceLogo)
                .background(logoColor, in: RoundedRectangle(cornerRadius: theme.shapes.serviceLogo))

            VStack(alignment: .leading, spacing: 2) {
                // اسم عربي (Bold) + اسم إنجليزي (Label) في سطر واحد.
                serviceTitle

                Text(description)
                    .mrasemText(theme.type.bodySm)
                    .foregroundColor(c.muted)
            }
            .frame(maxWidth: .infinity, minHeight: theme.dimens.minTouch, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onClick() }

            if let actionLabel {
                MrasemButton(actionLabel, variant: .outline, action: onClick)
            }
        }
        .padding(10)
        .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.serviceRow))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.serviceRow)
                .stroke(c.line, lineWidth: theme.dimens.borderWidth)
        )
    }

    /// الاسم العربي (Bold) وبعده الاسم الإنجليزي (Label) — سطر واحد زي التصميم.
    private var serviceTitle: some View {
        var attributed = AttributedString(name)
        attributed.font = theme.type.strong.font
        attributed.foregroundColor = theme.colors.ink

        if let nameEn {
            var english = AttributedString(" \(nameEn)")
            english.font = theme.type.label.font
            english.foregroundColor = theme.colors.muted
            attributed.append(english)
        }

        return Text(attributed)
    }
}

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
    let body: String

    init(title: String, body: String) {
        self.title = title
        self.body = body
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .mrasemText(theme.type.strong)
                .foregroundColor(c.ink)
            Text(body)
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
