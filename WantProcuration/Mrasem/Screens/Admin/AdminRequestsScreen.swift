//
//  AdminRequestsScreen.swift
//  Mrasem
//
//  Phase 15 — تاب «الطلبات» للأدمن (البوابة: الطلبات والتنبيهات): طلبات الضيوف بإجراءاتها، وإرسال تنبيه، وسجل التنبيهات.
//

import SwiftUI

struct AdminRequestsScreen: View {
    @StateObject private var model: AdminRequestsModel

    @State private var replying: RequestReplyDraft?
    @State private var programming: RequestProgramDraft?
    @State private var broadcasting: BroadcastDraft?

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: AdminRequestsModel(backend: context.backend, toastBus: context.toastBus))
    }

    var body: some View {
        AdminRequestsContent(
            state: model.uiState,
            onFilter: model.onFilter,
            onReply: { replying = model.replyDraft($0) },
            onResolve: model.resolve,
            onProgram: { programming = model.programDraft($0) },
            onBroadcast: { broadcasting = model.broadcastDraft() }
        )
        .sheet(item: $replying) { draft in
            RequestReplySheet(draft: draft, onSave: model.reply)
        }
        .sheet(item: $programming) { draft in
            RequestProgramSheet(draft: draft, days: model.programDays(draft.requestId), cars: model.carOptions(), onSave: model.addToProgram)
        }
        .sheet(item: $broadcasting) { draft in
            BroadcastSheet(draft: draft, delegations: model.delegationOptions(), onSave: model.send)
        }
    }
}

struct AdminRequestsContent: View {
    @Environment(\.mrasem) private var theme

    let state: AdminRequestsState
    let onFilter: (RequestFilter) -> Void
    let onReply: (String) -> Void
    let onResolve: (String) -> Void
    let onProgram: (String) -> Void
    let onBroadcast: () -> Void

    var body: some View {
        MrasemScreenContent {
            Text("mrasem_admin_requests_title")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)
                .accessibilityAddTraits(.isHeader)

            if state.hasDelegations {
                MrasemButton(mrasemString("mrasem_admin_requests_broadcast"), variant: .primary, block: true, action: onBroadcast)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RequestFilter.allCases, id: \.self) { filter in
                        MrasemChip(
                            mrasemString("mrasem_admin_filter_count", [
                                mrasemString(filter.titleKey), (state.counts[filter] ?? 0).toArabicDigits()
                            ]),
                            selected: filter == state.filter
                        ) { onFilter(filter) }
                    }
                }
            }

            if state.items.isEmpty {
                Text("mrasem_admin_requests_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            }
            ForEach(state.items) { item in
                requestCard(item)
            }

            history
        }
    }

    private func requestCard(_ item: AdminRequestItem) -> some View {
        MrasemCard(
            title: item.text,
            headerEnd: AnyView(MrasemPill(
                mrasemString(item.status == .new ? "mrasem_admin_req_status_new" : "mrasem_admin_req_status_done"),
                kind: item.status == .new ? .warn : .ok
            ))
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text(mrasemString("mrasem_admin_req_meta", [
                    item.memberName, item.delegationName,
                    mrasemString(item.kind == .visit ? "mrasem_admin_req_kind_visit" : "mrasem_admin_req_kind_question")
                ]))
                .mrasemText(theme.type.label)
                .foregroundColor(theme.colors.muted)

                if !item.reply.isEmpty {
                    Text(mrasemString("mrasem_admin_req_reply", [item.reply]))
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.ink)
                }

                if item.status == .new {
                    actions(item)
                }
            }
        }
    }

    @ViewBuilder
    private func actions(_ item: AdminRequestItem) -> some View {
        if item.kind == .visit {
            MrasemButton(mrasemString("mrasem_admin_req_to_program"), variant: .primary, block: true) { onProgram(item.id) }
        }
        MrasemButton(mrasemString("mrasem_admin_req_reply_action"), variant: .secondary, block: true) { onReply(item.id) }
        MrasemButton(mrasemString("mrasem_admin_req_resolve"), variant: .outline, block: true) { onResolve(item.id) }
    }

    @ViewBuilder
    private var history: some View {
        MrasemCard(title: mrasemString("mrasem_admin_history_title")) {
            if state.broadcasts.isEmpty {
                Text("mrasem_admin_history_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(state.broadcasts) { row in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.text)
                                .mrasemText(theme.type.body)
                                .foregroundColor(theme.colors.ink)
                            Text(mrasemString("mrasem_admin_history_meta", [
                                row.delegationName, mrasemString(row.audience.adminLabelKey),
                                row.readCount.toArabicDigits(), row.recipientCount.toArabicDigits()
                            ]))
                            .mrasemText(theme.type.label)
                            .foregroundColor(theme.colors.muted)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

#Preview("Admin requests - Light") {
    MrasemScreenPreview(.light) {
        AdminRequestsContent(
            state: .make(MrasemSeed.demo(), filter: .new), onFilter: { _ in }, onReply: { _ in },
            onResolve: { _ in }, onProgram: { _ in }, onBroadcast: {}
        )
    }
}
