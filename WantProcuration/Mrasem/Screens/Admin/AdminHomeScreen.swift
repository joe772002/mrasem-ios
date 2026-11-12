//
//  AdminHomeScreen.swift
//  Mrasem
//
//  Phase 14 — «الرئيسية» للأدمن (البوابة: لوحة التحكم): مؤشرات، «تحتاج إجراء»، وتحركات اليوم.
//

import SwiftUI

struct AdminHomeScreen: View {
    @StateObject private var model: AdminHomeModel
    private let context: MrasemAppContext

    init(context: MrasemAppContext) {
        self.context = context
        _model = StateObject(wrappedValue: AdminHomeModel(backend: context.backend))
    }

    var body: some View {
        AdminHomeContent(state: model.uiState, onAction: open, onDelegations: { context.roleShell.select(.admin(.delegations)) })
    }

    private func open(_ item: AdminActionItem) {
        switch item.kind {
        case .gaps:
            guard let id = item.delegationId else { return }
            context.adminNav.open(id)
            context.roleShell.select(.admin(.delegations))
        case .requests:
            context.roleShell.select(.soon(.adminRequests))
        case .conflicts:
            context.roleShell.select(.soon(.adminResources))
        }
    }
}

struct AdminHomeContent: View {
    @Environment(\.mrasem) private var theme

    let state: AdminHomeState
    let onAction: (AdminActionItem) -> Void
    let onDelegations: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        MrasemScreenContent {
            VStack(alignment: .leading, spacing: 4) {
                Text("mrasem_admin_home_title")
                    .mrasemText(theme.type.heroDest)
                    .foregroundColor(theme.colors.maroon)
                    .accessibilityAddTraits(.isHeader)
                Text(mrasemString("mrasem_admin_home_date", [StoreTime.dayLabel(state.today)]))
                    .mrasemText(theme.type.bodySm)
                    .foregroundColor(theme.colors.muted)
            }

            if state.isEmpty {
                MrasemCard(title: mrasemString("mrasem_admin_home_empty_title")) {
                    Text("mrasem_admin_home_empty_message")
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.muted)
                    MrasemButton(mrasemString("mrasem_admin_home_goto_delegations"), variant: .primary, block: true, action: onDelegations)
                }
            }

            kpis
            actions
            movements
        }
    }

    private var kpis: some View {
        let s = state.summary
        return LazyVGrid(columns: columns, spacing: 8) {
            MrasemKpiTile(value: s.activeDelegations.toArabicDigits(), label: mrasemString("mrasem_admin_kpi_delegations"))
            MrasemKpiTile(value: pair(s.activatedMembers, s.members), label: mrasemString("mrasem_admin_kpi_members"))
            MrasemKpiTile(value: pair(s.availableDrivers, s.totalDrivers), label: mrasemString("mrasem_admin_kpi_drivers"))
            MrasemKpiTile(value: pair(s.inbound, s.outbound), label: mrasemString("mrasem_admin_kpi_modes"))
            MrasemKpiTile(value: s.conflicts.toArabicDigits(), label: mrasemString("mrasem_admin_kpi_conflicts"))
            MrasemKpiTile(value: s.newRequests.toArabicDigits(), label: mrasemString("mrasem_admin_kpi_requests"))
        }
    }

    private func pair(_ a: Int, _ b: Int) -> String {
        a.toArabicDigits() + "/" + b.toArabicDigits()
    }

    private var actions: some View {
        MrasemCard(title: mrasemString("mrasem_admin_actions_title")) {
            if state.actions.isEmpty {
                Text("mrasem_admin_actions_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(spacing: 8) {
                    ForEach(state.actions) { item in
                        MrasemActionRow(title: title(item), subtitle: subtitle(item)) {
                            MrasemPill(item.count.toArabicDigits(), kind: .warn)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onAction(item) }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
    }

    private func title(_ item: AdminActionItem) -> String {
        switch item.kind {
        case .conflicts: return mrasemString("mrasem_admin_action_conflicts_title")
        case .requests: return mrasemString("mrasem_admin_action_requests_title")
        case .gaps: return item.delegationName
        }
    }

    private func subtitle(_ item: AdminActionItem) -> String {
        let count = item.count.toArabicDigits()
        switch item.kind {
        case .conflicts: return mrasemString("mrasem_admin_action_conflicts_subtitle", [count])
        case .requests: return mrasemString("mrasem_admin_action_requests_subtitle", [count])
        case .gaps: return mrasemString("mrasem_admin_action_gaps_subtitle", [count])
        }
    }

    private var movements: some View {
        MrasemCard(title: mrasemString("mrasem_admin_movements_title")) {
            if state.movements.isEmpty {
                Text("mrasem_admin_movements_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(spacing: 8) {
                    ForEach(state.movements) { move in
                        MrasemActionRow(title: move.time + "  " + move.title, subtitle: subtitle(move)) {
                            if move.hasConflict {
                                MrasemPill(mrasemString("mrasem_admin_pill_conflict"), kind: .warn)
                            }
                        }
                    }
                }
            }
        }
    }

    private func subtitle(_ move: AdminMovement) -> String {
        move.driverName.map { mrasemString("mrasem_admin_movement_subtitle", [move.delegationName, $0]) }
            ?? mrasemString("mrasem_admin_movement_no_driver", [move.delegationName])
    }
}

#Preview("Admin home - Light") {
    MrasemScreenPreview(.light) {
        AdminHomeContent(state: AdminHomeBuilder.make(MrasemSeed.demo(), today: "2026-11-24"), onAction: { _ in }, onDelegations: {})
    }
}

#Preview("Admin home - Dark") {
    MrasemScreenPreview(.dark) {
        AdminHomeContent(state: AdminHomeBuilder.make(MrasemSeed.demo(), today: "2026-11-24"), onAction: { _ in }, onDelegations: {})
    }
}

#Preview("Admin home empty - Light") {
    MrasemScreenPreview(.light) {
        AdminHomeContent(state: AdminHomeBuilder.make(MrasemDatabase.blank(), today: "2026-11-24"), onAction: { _ in }, onDelegations: {})
    }
}
