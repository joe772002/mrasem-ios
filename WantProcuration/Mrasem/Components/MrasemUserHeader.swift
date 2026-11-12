//
//  MrasemUserHeader.swift
//  Mrasem
//
//  Phase 13 — هيدر الـ Shell بعد تعدد المستخدمين: العلامة + المستخدم الحالي (زر التبديل + تنبيهاته غير المقروءة)
//  + اختيار الوفد للمنسق والأدمن. بيحل محل مفتاحي الدور والنوع.
//

import SwiftUI

struct MrasemUserHeader: View {
    @Environment(\.mrasem) private var theme

    let title: String
    let subtitle: String
    let userName: String
    let roleLabel: String
    let unread: Int
    let delegations: [DelegationChoice]
    let selectedDelegationId: String?
    let onSwitchUser: () -> Void
    let onSelectDelegation: (String) -> Void
    /// زر الإعدادات (للأدمن بس). `nil` = مش ظاهر.
    var onSettings: (() -> Void)?

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
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)

                if let onSettings {
                    settingsButton(onSettings)
                }

                switcher
            }

            if !delegations.isEmpty {
                delegationRow
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(c.headerBg.ignoresSafeArea(edges: .top))
    }

    // MARK: - الإعدادات

    private func settingsButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MrasemIcons.settings
                .foregroundColor(theme.colors.onHeader)
                .frame(minWidth: theme.dimens.minTouch, minHeight: theme.dimens.minTouch)
        }
        .accessibilityLabel(mrasemString("mrasem_header_settings"))
    }

    // MARK: - زر التبديل

    private var switcher: some View {
        let c = theme.colors

        return HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(userName)
                    .mrasemText(theme.type.roleSwitch)
                    .foregroundColor(c.onHeader)
                    .lineLimit(1)
                Text(roleLabel)
                    .mrasemText(theme.type.caption)
                    .foregroundColor(c.onHeader.opacity(0.8))
                    .lineLimit(1)
            }

            MrasemAvatarInitial(userName)
                .overlay(Circle().stroke(c.onHeader.opacity(0.6), lineWidth: theme.dimens.borderWidth))
                .overlay(alignment: .topTrailing) { unreadBadge.offset(x: 6, y: -6) }
        }
        .frame(minHeight: theme.dimens.minTouch)
        .contentShape(Rectangle())
        .onTapGesture { onSwitchUser() }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(userName + "، " + roleLabel)
        .accessibilityHint(mrasemString("mrasem_header_switch"))
        .accessibilityValue(unread > 0 ? mrasemString("mrasem_users_unread_a11y", [unread.toArabicDigits()]) : "")
    }

    @ViewBuilder
    private var unreadBadge: some View {
        if unread > 0 {
            Text(unread.toArabicDigits())
                .mrasemText(theme.type.caption)
                .foregroundColor(theme.colors.ink)
                .padding(.horizontal, 5)
                .frame(minWidth: 18, minHeight: 18)
                .background(theme.colors.gold, in: Capsule())
        }
    }

    // MARK: - الوفد

    @ViewBuilder
    private var delegationRow: some View {
        let selected = delegations.first { $0.id == selectedDelegationId } ?? delegations.first
        let label = mrasemString("mrasem_header_delegation_label", [selected?.name ?? ""])

        if delegations.count > 1 {
            Menu {
                ForEach(delegations) { choice in
                    Button(choice.name) { onSelectDelegation(choice.id) }
                }
            } label: {
                delegationLabel(label)
            }
            .accessibilityLabel(label)
        } else {
            delegationLabel(label)
        }
    }

    private func delegationLabel(_ text: String) -> some View {
        Text(text)
            .mrasemText(theme.type.chip)
            .foregroundColor(theme.colors.onHeader)
            .lineLimit(1)
            .frame(minHeight: theme.dimens.minTouch)
            .padding(.horizontal, 12)
            .overlay(Capsule().stroke(theme.colors.onHeader.opacity(0.5), lineWidth: theme.dimens.borderWidth))
    }
}

#Preview("UserHeader - Light") {
    MrasemUserHeader(
        title: "مراسم", subtitle: "وزارة العدل", userName: "سعيد المري", roleLabel: "منسق", unread: 3,
        delegations: [DelegationChoice(id: "d1", name: "وفد المملكة المتحدة"), DelegationChoice(id: "d2", name: "وفد آخر")],
        selectedDelegationId: "d1", onSwitchUser: {}, onSelectDelegation: { _ in }
    )
    .mrasemTheme(.light)
    .environment(\.layoutDirection, .rightToLeft)
}
