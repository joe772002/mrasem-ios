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
    /// الزي المطلوب (نص حر). nil أو فاضي = مفيش حاجة تتعرض.
    let dressCode: String?
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
        dressCode: String? = nil,
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
        self.dressCode = dressCode
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

            if let dressCode, !dressCode.isEmpty {
                dressCodeBadge(dressCode)
            }
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

    /// الزي المطلوب في طرف الصف (الجهة الفاضية)، النص بيلتف لو طويل.
    private func dressCodeBadge(_ value: String) -> some View {
        let c = theme.colors
        return VStack(alignment: .leading, spacing: 2) {
            Text(mrasemString("mrasem_plan_dress_code"))
                .mrasemText(theme.type.label)
                .foregroundColor(c.muted)
            Text(value)
                .mrasemText(theme.type.chip)
                .foregroundColor(c.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 104, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(c.tint, in: RoundedRectangle(cornerRadius: theme.shapes.pill))
        .accessibilityElement(children: .combine)
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
                .accessibilityHidden(true)

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
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)

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
