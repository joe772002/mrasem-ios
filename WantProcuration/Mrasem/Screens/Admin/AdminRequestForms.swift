//
//  AdminRequestForms.swift
//  Mrasem
//
//  Phase 15 — نماذج الطلبات: الرد، الإضافة للبرنامج، وإرسال تنبيه.
//

import SwiftUI

struct RequestReplySheet: View {
    @State var draft: RequestReplyDraft
    let onSave: (RequestReplyDraft) -> String?

    var body: some View {
        AdminFormSheet(titleKey: "mrasem_admin_form_reply", onSave: { onSave(draft) }, delete: nil) {
            MrasemTextField(value: $draft.text, label: mrasemString("mrasem_admin_field_reply"), singleLine: false)
        }
    }
}

struct RequestProgramSheet: View {
    @State var draft: RequestProgramDraft
    let days: [String]
    let cars: [PickerOption]
    let onSave: (RequestProgramDraft) -> String?

    var body: some View {
        AdminFormSheet(titleKey: "mrasem_admin_form_to_program", onSave: { onSave(draft) }, delete: nil) {
            ValueSelect(label: mrasemString("mrasem_admin_field_day"), values: days.isEmpty ? [draft.date] : days,
                        title: { StoreTime.dayLabel($0) }, selection: $draft.date)
            MrasemTextField(value: $draft.time, label: mrasemString("mrasem_admin_field_time"), placeholder: "10:00", ltr: true)
            IdSelect(label: mrasemString("mrasem_admin_field_car"), options: cars, selection: $draft.carId)
        }
    }
}

struct BroadcastSheet: View {
    @State var draft: BroadcastDraft
    let delegations: [PickerOption]
    let onSave: (BroadcastDraft) -> String?

    var body: some View {
        AdminFormSheet(titleKey: "mrasem_admin_form_broadcast", onSave: { onSave(draft) }, delete: nil) {
            ValueSelect(
                label: mrasemString("mrasem_admin_field_delegation"),
                values: delegations.compactMap(\.id),
                title: { id in delegations.first { $0.id == id }?.label ?? id },
                selection: $draft.delegationId
            )
            ValueSelect(label: mrasemString("mrasem_admin_field_audience"), values: NoticeAudience.broadcastChoices,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.audience)
            MrasemTextField(value: $draft.text, label: mrasemString("mrasem_admin_field_broadcast_text"), singleLine: false)
        }
    }
}
