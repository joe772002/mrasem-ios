//
//  MrasemInputs.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemInputs.kt
//

import SwiftUI

struct MrasemTextField: View {
    @Environment(\.mrasem) private var theme

    @Binding var value: String
    let label: String?
    let placeholder: String
    let singleLine: Bool
    /// للقيم اللاتينية (هواتف، لوحات) — قاعدة B6.
    let ltr: Bool

    init(
        value: Binding<String>,
        label: String? = nil,
        placeholder: String = "",
        singleLine: Bool = true,
        ltr: Bool = false
    ) {
        self._value = value
        self.label = label
        self.placeholder = placeholder
        self.singleLine = singleLine
        self.ltr = ltr
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .mrasemText(theme.type.label)
                    .foregroundColor(c.muted)
            }

            TextField(
                "",
                text: $value,
                prompt: Text(placeholder)
                    .mrasemText(theme.type.body)
                    .foregroundColor(c.muted),
                axis: singleLine ? .horizontal : .vertical
            )
            .mrasemText(theme.type.body)
            .foregroundColor(c.ink)
            .tint(c.maroon)
            .textFieldStyle(.plain)
            .lineLimit(singleLine ? 1 : nil)
            .frame(minHeight: theme.dimens.minTouch)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.field))
            .overlay(
                RoundedRectangle(cornerRadius: theme.shapes.field)
                    .stroke(c.line, lineWidth: theme.dimens.borderWidth)
            )
            .environment(\.layoutDirection, ltr ? .leftToRight : .rightToLeft)
        }
    }
}

struct MrasemSelect: View {
    @Environment(\.mrasem) private var theme

    let options: [String]
    @Binding var selectedIndex: Int
    let label: String?

    init(options: [String], selectedIndex: Binding<Int>, label: String? = nil) {
        self.options = options
        self._selectedIndex = selectedIndex
        self.label = label
    }

    var body: some View {
        let c = theme.colors
        let current = options.indices.contains(selectedIndex) ? options[selectedIndex] : ""

        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .mrasemText(theme.type.label)
                    .foregroundColor(c.muted)
            }

            Menu {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        selectedIndex = index
                    } label: {
                        Text(option)
                            .mrasemText(theme.type.body)
                            .foregroundColor(c.ink)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(current)
                        .mrasemText(theme.type.body)
                        .foregroundColor(c.ink)
                    Spacer(minLength: 0)
                    Text("▾")
                        .mrasemText(theme.type.body)
                        .foregroundColor(c.muted)
                }
                .frame(minHeight: theme.dimens.minTouch)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(c.surface, in: RoundedRectangle(cornerRadius: theme.shapes.field))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.shapes.field)
                        .stroke(c.line, lineWidth: theme.dimens.borderWidth)
                )
            }
            .accessibilityLabel(label ?? current)
        }
    }
}

struct MrasemAskBar: View {
    @Environment(\.mrasem) private var theme

    @Binding var value: String
    let placeholder: String
    let sendLabel: String
    let onSend: () -> Void

    init(
        value: Binding<String>,
        placeholder: String,
        sendLabel: String,
        onSend: @escaping () -> Void
    ) {
        self._value = value
        self.placeholder = placeholder
        self.sendLabel = sendLabel
        self.onSend = onSend
    }

    var body: some View {
        HStack(spacing: 8) {
            MrasemTextField(value: $value, placeholder: placeholder)
            MrasemButton(sendLabel, variant: .primary, enabled: !value.trimmingCharacters(in: .whitespaces).isEmpty) {
                onSend()
            }
        }
    }
}
