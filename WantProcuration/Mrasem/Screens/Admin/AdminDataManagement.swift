//
//  AdminDataManagement.swift
//  Mrasem
//
//  Phase 15 — «إدارة البيانات»: مسح وفد، إعادة تحميل بيانات العرض، ومسح كل البيانات.
//  كل فعل هنا مدمّر فبيمر على تأكيد صريح (G3).
//

import SwiftUI

struct AdminDataManagementCard: View {
    @Environment(\.mrasem) private var theme

    let state: AdminSettingsState
    let onDeleteDelegation: (String) -> Void
    let onReloadDemo: () -> Void
    let onWipeAll: () -> Void

    private enum Pending: Equatable {
        case delegation(String)
        case demo
        case wipe
    }

    @State private var pending: Pending?
    @State private var delegationId: String?

    var body: some View {
        MrasemCard(title: mrasemString("mrasem_admin_data_title")) {
            VStack(alignment: .leading, spacing: 10) {
                Text(mrasemString("mrasem_admin_data_counts", [
                    state.counts.delegations.toArabicDigits(), state.counts.members.toArabicDigits(),
                    state.counts.places.toArabicDigits(), state.counts.requests.toArabicDigits()
                ]))
                .mrasemText(theme.type.body)
                .foregroundColor(theme.colors.ink)

                if !state.delegations.isEmpty {
                    IdSelect(
                        label: mrasemString("mrasem_admin_data_delegation"),
                        options: [PickerOption(id: nil, label: mrasemString("mrasem_admin_none"))] + state.delegations,
                        selection: $delegationId
                    )
                    MrasemButton(mrasemString("mrasem_admin_data_delete_delegation"), variant: .outline, block: true) {
                        if let delegationId { pending = .delegation(delegationId) }
                    }
                }

                MrasemButton(mrasemString("mrasem_admin_data_reload_demo"), variant: .secondary, block: true) { pending = .demo }
                MrasemButton(mrasemString("mrasem_admin_data_wipe_all"), variant: .outline, block: true) { pending = .wipe }
            }
        }
        .alert(titleKey, isPresented: isPending, actions: {
            Button(mrasemString("mrasem_admin_data_confirm"), role: .destructive, action: confirm)
            Button(mrasemString("mrasem_admin_form_cancel"), role: .cancel) {}
        }, message: {
            Text(mrasemString(messageKey))
        })
    }

    private var isPending: Binding<Bool> {
        Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })
    }

    private var titleKey: String {
        switch pending {
        case .delegation: return mrasemString("mrasem_admin_data_delete_delegation")
        case .demo: return mrasemString("mrasem_admin_data_reload_demo")
        case .wipe, .none: return mrasemString("mrasem_admin_data_wipe_all")
        }
    }

    private var messageKey: String {
        switch pending {
        case .delegation: return "mrasem_admin_data_delete_delegation_message"
        case .demo: return "mrasem_admin_data_reload_demo_message"
        case .wipe, .none: return "mrasem_admin_data_wipe_all_message"
        }
    }

    private func confirm() {
        switch pending {
        case let .delegation(id):
            onDeleteDelegation(id)
            delegationId = nil
        case .demo:
            onReloadDemo()
        case .wipe:
            onWipeAll()
        case .none:
            break
        }
        pending = nil
    }
}
