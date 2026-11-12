//
//  AdminDelegationsScreen.swift
//  Mrasem
//
//  Phase 14 — تاب «الوفود» للأدمن: قائمة بفلاتر وإضافة، وتفاصيل الوفد لما نفتح واحد.
//

import SwiftUI

struct AdminDelegationsScreen: View {
    @ObservedObject private var nav: AdminNavigator
    @StateObject private var model: AdminDelegationsModel
    private let context: MrasemAppContext

    @State private var adding: DelegationDraft?

    init(context: MrasemAppContext) {
        self.context = context
        self._nav = ObservedObject(wrappedValue: context.adminNav)
        _model = StateObject(wrappedValue: AdminDelegationsModel(
            backend: context.backend, nav: context.adminNav, toastBus: context.toastBus
        ))
    }

    var body: some View {
        if let id = nav.openDelegationId {
            AdminDelegationDetailScreen(context: context, delegationId: id)
        } else {
            AdminDelegationsContent(
                state: model.uiState,
                onFilter: model.onFilter,
                onOpen: model.onOpen,
                onAdd: { adding = model.newDraft() }
            )
            .sheet(item: $adding) { draft in
                DelegationFormSheet(draft: draft, hotels: model.hotels(), venues: model.venues(), onSave: model.save, onDelete: nil)
            }
        }
    }
}

/// عشان `.sheet(item:)`: مسوّدة واحدة بتتعرض في الوقت الواحد.
extension DelegationDraft: Identifiable {}

struct AdminDelegationsContent: View {
    @Environment(\.mrasem) private var theme

    let state: AdminDelegationsState
    let onFilter: (DelegationFilter) -> Void
    let onOpen: (String) -> Void
    let onAdd: () -> Void

    var body: some View {
        MrasemScreenContent {
            Text("mrasem_admin_delegations_title")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)
                .accessibilityAddTraits(.isHeader)

            MrasemButton(mrasemString("mrasem_admin_delegations_add"), variant: .primary, block: true, action: onAdd)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DelegationFilter.allCases, id: \.self) { filter in
                        MrasemChip(chipTitle(filter), selected: filter == state.filter) { onFilter(filter) }
                    }
                }
            }

            if state.rows.isEmpty {
                Text("mrasem_admin_delegations_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(spacing: 8) {
                    ForEach(state.rows) { row in
                        MrasemActionRow(title: row.name, subtitle: subtitle(row)) {
                            VStack(alignment: .trailing, spacing: 4) {
                                MrasemPill(mrasemString(row.status.labelKey), kind: row.status == .active ? .ok : .neutral)
                                MrasemPill(
                                    mrasemString("mrasem_admin_readiness", [row.readiness.toArabicDigits()]),
                                    kind: row.missing == 0 ? .ok : .warn
                                )
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onOpen(row.id) }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
    }

    private func chipTitle(_ filter: DelegationFilter) -> String {
        mrasemString("mrasem_admin_filter_count", [mrasemString(filter.titleKey), (state.counts[filter] ?? 0).toArabicDigits()])
    }

    private func subtitle(_ row: DelegationRow) -> String {
        mrasemString("mrasem_admin_delegation_subtitle", [
            mrasemString(row.mode.adminLabelKey),
            row.start.toArabicDigits(), row.end.toArabicDigits(),
            row.memberCount.toArabicDigits()
        ])
    }
}

#Preview("Admin delegations - Light") {
    MrasemScreenPreview(.light) {
        AdminDelegationsContent(
            state: .make(MrasemSeed.demo(), filter: .all), onFilter: { _ in }, onOpen: { _ in }, onAdd: {}
        )
    }
}

#Preview("Admin delegations - Dark") {
    MrasemScreenPreview(.dark) {
        AdminDelegationsContent(
            state: .make(MrasemSeed.demo(), filter: .active), onFilter: { _ in }, onOpen: { _ in }, onAdd: {}
        )
    }
}
