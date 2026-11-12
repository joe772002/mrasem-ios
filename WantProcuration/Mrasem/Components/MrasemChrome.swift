//
//  MrasemChrome.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemChrome.kt
//

import SwiftUI

/// الهيدر الثابت: العلامة + مفتاح الدور + مفتاح نوع المهمة.
struct MrasemHeader: View {
    @Environment(\.mrasem) private var theme

    let title: String
    let subtitle: String
    let roleOptions: [String]
    @Binding var roleIndex: Int
    let modeOptions: [String]
    @Binding var modeIndex: Int

    init(
        title: String,
        subtitle: String,
        roleOptions: [String],
        roleIndex: Binding<Int>,
        modeOptions: [String],
        modeIndex: Binding<Int>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.roleOptions = roleOptions
        self._roleIndex = roleIndex
        self.modeOptions = modeOptions
        self._modeIndex = modeIndex
    }

    var body: some View {
        let c = theme.colors

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .mrasemText(theme.type.brandTitle)
                        .foregroundColor(c.onHeader)
                    Text(subtitle)
                        .mrasemText(theme.type.brandSub)
                        .foregroundColor(c.onHeader.opacity(0.8))
                }

                Spacer(minLength: 8)

                MrasemSegmented(options: roleOptions, selectedIndex: $roleIndex, textStyle: theme.type.roleSwitch)
            }

            MrasemSegmented(options: modeOptions, selectedIndex: $modeIndex, equalWidth: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(c.headerBg.ignoresSafeArea(edges: .top))
    }
}

/// عنصر في الـ bottom bar.
struct MrasemBottomBarItem: Identifiable {
    let label: String
    let icon: MrasemIcon

    var id: String { label }
}

struct MrasemBottomBar: View {
    @Environment(\.mrasem) private var theme

    let items: [MrasemBottomBarItem]
    @Binding var selectedIndex: Int

    init(items: [MrasemBottomBarItem], selectedIndex: Binding<Int>) {
        self.items = items
        self._selectedIndex = selectedIndex
    }

    var body: some View {
        let c = theme.colors

        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isSelected = index == selectedIndex

                VStack(spacing: 2) {
                    item.icon
                        .foregroundStyle(isSelected ? c.maroon : c.muted)
                        .frame(width: theme.dimens.bottomBarIcon, height: theme.dimens.bottomBarIcon)

                    Text(item.label)
                        .mrasemText(theme.type.caption)
                        .foregroundColor(isSelected ? c.maroon : c.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .contentShape(Rectangle())
                .onTapGesture { selectedIndex = index }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(item.label)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .frame(maxWidth: .infinity)
        .background(c.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(c.line)
                .frame(height: theme.dimens.borderWidth)
        }
    }
}
