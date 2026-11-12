//
//  MrasemControls.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemControls.kt
//

import SwiftUI

enum ButtonVariant {
    case primary
    case secondary
    case ghost
    case outline
}

struct MrasemButton: View {
    @Environment(\.mrasem) private var theme

    let text: String
    let variant: ButtonVariant
    let block: Bool
    let enabled: Bool
    let action: () -> Void

    init(
        _ text: String,
        variant: ButtonVariant = .secondary,
        block: Bool = false,
        enabled: Bool = true,
        action: @escaping () -> Void = {}
    ) {
        self.text = text
        self.variant = variant
        self.block = block
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        let c = theme.colors
        let hasBorder = variant == .secondary || variant == .outline

        return Text(text)
            .mrasemText(theme.type.button)
            .foregroundColor(foreground)
            .frame(maxWidth: block ? .infinity : nil)
            .frame(minHeight: theme.dimens.minTouch)
            .padding(.horizontal, 12)
            .padding(.vertical, block ? 12 : 8)
            .background(background, in: RoundedRectangle(cornerRadius: theme.shapes.button))
            .overlay {
                if hasBorder {
                    RoundedRectangle(cornerRadius: theme.shapes.button)
                        .stroke(c.line, lineWidth: theme.dimens.borderWidth)
                }
            }
            .opacity(enabled ? 1 : 0.5)
            .contentShape(Rectangle())
            .onTapGesture {
                if enabled { action() }
            }
            .disabled(!enabled)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(text)
    }

    private var background: Color {
        switch variant {
        case .primary: return theme.colors.maroon
        case .secondary, .outline: return theme.colors.surface
        case .ghost: return .clear
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: return theme.colors.onMaroon
        case .secondary: return theme.colors.ink
        case .ghost: return theme.colors.maroonInk
        case .outline: return theme.colors.maroon
        }
    }
}

struct MrasemChip: View {
    @Environment(\.mrasem) private var theme

    let text: String
    let selected: Bool
    let action: () -> Void

    init(_ text: String, selected: Bool = false, action: @escaping () -> Void = {}) {
        self.text = text
        self.selected = selected
        self.action = action
    }

    var body: some View {
        let c = theme.colors

        Text(text)
            .mrasemText(theme.type.chip)
            .foregroundColor(selected ? c.bg : c.ink)
            .frame(minHeight: theme.dimens.minTouch)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(selected ? c.ink : c.surface, in: Capsule())
            .overlay {
                Capsule().stroke(selected ? c.ink : c.line, lineWidth: theme.dimens.borderWidth)
            }
            .contentShape(Capsule())
            .onTapGesture { action() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(text)
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// مفتاح مجزّأ (الضيف | فريق المراسم، …). ألوانه مصمّمة للهيدر الداكن.
struct MrasemSegmented: View {
    @Environment(\.mrasem) private var theme

    let options: [String]
    @Binding var selectedIndex: Int
    let equalWidth: Bool
    let textStyle: MrasemTextStyle?

    init(
        options: [String],
        selectedIndex: Binding<Int>,
        equalWidth: Bool = false,
        textStyle: MrasemTextStyle? = nil
    ) {
        self.options = options
        self._selectedIndex = selectedIndex
        self.equalWidth = equalWidth
        self.textStyle = textStyle
    }

    var body: some View {
        let c = theme.colors

        HStack(spacing: 3) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, label in
                let isSelected = index == selectedIndex

                Text(label)
                    .mrasemText(textStyle ?? theme.type.seg)
                    .foregroundColor(isSelected ? c.segmentSelectedText : c.onHeader)
                    .frame(maxWidth: equalWidth ? .infinity : nil)
                    .frame(minHeight: 40)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        isSelected ? c.segmentSelectedBg : Color.clear,
                        in: RoundedRectangle(cornerRadius: theme.shapes.segmentButton)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selectedIndex = index }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(label)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(c.segmentTrack, in: RoundedRectangle(cornerRadius: theme.shapes.button))
    }
}

struct MrasemAvatarInitial: View {
    @Environment(\.mrasem) private var theme

    let name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some View {
        let c = theme.colors
        let initial = name.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? ""

        Text(initial)
            .mrasemText(theme.type.avatarInitial)
            .foregroundColor(c.onMaroon)
            .frame(width: theme.dimens.avatar, height: theme.dimens.avatar)
            .background(c.maroon, in: Circle())
    }
}

/// نمط لوحة السيارة — لازم يبقى موجود في Data (Phase 2).
enum PlateStyle {
    case qatar
    case unitedKingdom
}

/// لوحة سيارة (LTR دائمًا — قاعدة B6).
struct MrasemPlateBadge: View {
    @Environment(\.mrasem) private var theme

    let plate: String
    let country: String
    let style: PlateStyle

    init(plate: String, country: String, style: PlateStyle) {
        self.plate = plate
        self.country = country
        self.style = style
    }

    var body: some View {
        let isQatar = style == .qatar
        let body = isQatar ? MrasemFixedColors.plateBg : MrasemFixedColors.plateUkBg
        let strip = isQatar ? MrasemFixedColors.plateQaStrip : MrasemFixedColors.plateUkStrip

        HStack(spacing: 0) {
            Text(country)
                .mrasemText(theme.type.plateCountry)
                .foregroundColor(theme.colors.onMaroon)
                .padding(.horizontal, 5)
                .padding(.vertical, 4)
                .background(strip)

            Text(plate)
                .mrasemText(theme.type.plateNumber)
                .foregroundColor(MrasemFixedColors.plateText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
        }
        .background(body, in: RoundedRectangle(cornerRadius: theme.shapes.plate))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.plate)
                .stroke(MrasemFixedColors.plateText, lineWidth: 2)
        )
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct MrasemDayTabs: View {
    @Environment(\.mrasem) private var theme

    let labels: [String]
    @Binding var selectedIndex: Int

    init(labels: [String], selectedIndex: Binding<Int>) {
        self.labels = labels
        self._selectedIndex = selectedIndex
    }

    var body: some View {
        let c = theme.colors

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    let isSelected = index == selectedIndex

                    Text(label)
                        .mrasemText(theme.type.chip)
                        .foregroundColor(isSelected ? c.onMaroon : c.ink)
                        .frame(minHeight: theme.dimens.minTouch)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            isSelected ? c.maroon : c.surface,
                            in: RoundedRectangle(cornerRadius: theme.shapes.dayButton)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: theme.shapes.dayButton)
                                .stroke(isSelected ? c.maroon : c.line, lineWidth: theme.dimens.borderWidth)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedIndex = index }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(label)
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
        }
    }
}
