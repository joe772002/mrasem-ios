//
//  UserPickerScreen.swift
//  Mrasem
//
//  Phase 13 — «اختر المستخدم»: بعد الـ Splash وعند ضغط زر التبديل في الهيدر. نسخة عرض من غير كلمة مرور (G6).
//

import SwiftUI

struct UserPickerScreen: View {
    @Environment(\.mrasem) private var theme
    @StateObject private var model: UserPickerModel

    init(context: MrasemAppContext) {
        self._model = StateObject(wrappedValue: UserPickerModel(context: context))
    }

    var body: some View {
        let c = theme.colors
        let state = model.uiState

        ScrollView {
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("mrasem_users_title")
                        .mrasemText(theme.type.heroDest)
                        .foregroundColor(c.maroon)
                        .accessibilityAddTraits(.isHeader)
                    Text("mrasem_users_subtitle")
                        .mrasemText(theme.type.bodySm)
                        .foregroundColor(c.muted)
                }

                ForEach(state.sections) { section in
                    MrasemCard(title: mrasemString(section.kind.titleKey)) {
                        VStack(spacing: 8) {
                            ForEach(section.entries) { entry in
                                row(entry)
                            }
                        }
                    }
                }

                if state.onlyOneUser {
                    Text("mrasem_users_empty_hint")
                        .mrasemText(theme.type.bodySm)
                        .foregroundColor(c.muted)
                }

                if state.canGoBack {
                    MrasemButton(mrasemString("mrasem_users_back"), variant: .ghost, block: true) { model.onBack() }
                }
            }
            .padding(.horizontal, theme.dimens.screenHorizontal)
            .padding(.vertical, theme.dimens.screenTop)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(c.bg.ignoresSafeArea())
    }

    private func row(_ entry: UserEntry) -> some View {
        HStack(spacing: 10) {
            MrasemAvatarInitial(entry.name)

            MrasemActionRow(title: entry.name, subtitle: entry.detail) {
                VStack(alignment: .trailing, spacing: 4) {
                    MrasemPill(mrasemString(entry.role.labelKey))
                    if entry.isCurrent {
                        MrasemPill(mrasemString("mrasem_users_current"), kind: .ok)
                    }
                    if entry.unread > 0 {
                        MrasemPill(mrasemString("mrasem_users_unread", [entry.unread.toArabicDigits()]), kind: .warn)
                    }
                }
            }
        }
        .frame(minHeight: theme.dimens.minTouch)
        .contentShape(Rectangle())
        .onTapGesture { model.onSelect(entry) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(entry.isCurrent ? [.isSelected] : [])
    }
}

#Preview("Users - Light") {
    UserPickerScreen(context: .preview())
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Users - Dark") {
    UserPickerScreen(context: .preview(user: .team("u2")))
        .mrasemTheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}
