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
    var content: () -> Content

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

    var content: () -> Content

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
        Text(text)
            .mrasemText(theme.type.pill)
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(background, in: RoundedRectangle(cornerRadius: theme.shapes.pill))
    }

    private var background: Color {
        switch kind {
        case .neutral: return theme.colors.tint
        case .ok: return theme.colors.pillOkBg
        case .warn: return theme.colors.pillWarnBg
        }
    }

    private var foreground: Color {
        switch kind {
        case .neutral: return theme.colors.maroonInk
        case .ok: return theme.colors.ok
        case .warn: return theme.colors.warn
        }
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
        .accessibilityElement(children: .combine)
    }
}
