//
//  AdminDelegationDetailScreen.swift
//  Mrasem
//
//  Phase 14 — تفاصيل الوفد للأدمن: الرأس، الأعضاء والتعيينات، البرنامج، الإقامة، الطلبات + نماذج التعديل.
//

import SwiftUI

/// النموذج المفتوح حالياً.
enum AdminDetailSheet: Identifiable {
    case delegation(DelegationDraft)
    case member(MemberDraft)
    case item(ProgramDraft)

    var id: String {
        switch self {
        case let .delegation(draft): return "d-" + draft.id
        case let .member(draft): return "m-" + draft.id
        case let .item(draft): return "i-" + draft.id + draft.date
        }
    }
}

struct AdminDelegationDetailScreen: View {
    @StateObject private var model: AdminDelegationDetailModel
    private let context: MrasemAppContext

    @State private var sheet: AdminDetailSheet?

    init(context: MrasemAppContext, delegationId: String) {
        self.context = context
        _model = StateObject(wrappedValue: AdminDelegationDetailModel(
            backend: context.backend, delegationId: delegationId, nav: context.adminNav, toastBus: context.toastBus
        ))
    }

    var body: some View {
        Group {
            if let detail = model.uiState {
                AdminDelegationDetailContent(detail: detail, actions: actions)
            } else {
                // الوفد اتحذف: نرجع للقائمة.
                Color.clear.onAppear { model.close() }
            }
        }
        .sheet(item: $sheet) { sheetContent($0) }
    }

    private var actions: AdminDetailActions {
        AdminDetailActions(
            onBack: model.close,
            onEdit: { if let draft = model.delegationDraft() { sheet = .delegation(draft) } },
            onStatus: model.setStatus,
            onAddMember: { sheet = .member(model.memberDraft(nil)) },
            onEditMember: { sheet = .member(model.memberDraft($0)) },
            onAddItem: { sheet = .item(model.itemDraft(nil, date: $0)) },
            onEditItem: { sheet = .item(model.itemDraft($0)) },
            onPostpone: model.postpone,
            onResolve: model.resolve
        )
    }

    @ViewBuilder
    private func sheetContent(_ item: AdminDetailSheet) -> some View {
        switch item {
        case let .delegation(draft):
            DelegationFormSheet(draft: draft, hotels: model.hotels(), venues: model.venues(),
                                onSave: model.saveDelegation, onDelete: { model.deleteDelegation() })
        case let .member(draft):
            MemberFormSheet(draft: draft, escorts: model.escorts(), cars: model.cars(), onSave: model.saveMember,
                            onDelete: draft.isNew ? nil : { model.deleteMember(draft.id) })
        case let .item(draft):
            ProgramFormSheet(draft: draft, days: model.days, places: model.places(), cars: model.cars(),
                             onSave: model.saveItem, onDelete: draft.isNew ? nil : { model.deleteItem(draft.id) })
        }
    }
}

struct AdminDetailActions {
    let onBack: () -> Void
    let onEdit: () -> Void
    let onStatus: (DelegationStatus) -> Void
    let onAddMember: () -> Void
    let onEditMember: (String) -> Void
    let onAddItem: (String?) -> Void
    let onEditItem: (String) -> Void
    let onPostpone: (String) -> Void
    let onResolve: (String) -> Void

    static let none = AdminDetailActions(
        onBack: {}, onEdit: {}, onStatus: { _ in }, onAddMember: {}, onEditMember: { _ in },
        onAddItem: { _ in }, onEditItem: { _ in }, onPostpone: { _ in }, onResolve: { _ in }
    )
}

struct AdminDelegationDetailContent: View {
    @Environment(\.mrasem) private var theme

    let detail: AdminDelegationDetail
    let actions: AdminDetailActions

    var body: some View {
        MrasemScreenContent {
            MrasemButton(mrasemString("mrasem_admin_back"), variant: .ghost, action: actions.onBack)
            AdminDelegationHeaderCard(detail: detail, actions: actions)
            AdminMembersCard(members: detail.members, actions: actions)
            AdminProgramCard(days: detail.days, actions: actions)
            AdminStayCard(hotelName: detail.hotelName, members: detail.members)
            AdminRequestsCard(requests: detail.requests, actions: actions)
        }
    }
}

#Preview("Admin detail - Light") {
    MrasemScreenPreview(.light) {
        AdminDelegationDetailContent(
            detail: AdminDelegationDetailBuilder.make(MrasemSeed.demo(), id: "d1")!, actions: .none
        )
    }
}

#Preview("Admin detail - Dark") {
    MrasemScreenPreview(.dark) {
        AdminDelegationDetailContent(
            detail: AdminDelegationDetailBuilder.make(MrasemSeed.demo(), id: "d3")!, actions: .none
        )
    }
}
