//
//  AdminSettingsForms.swift
//  Mrasem
//
//  Phase 15 — نماذج الإعدادات: عضو الفريق (الدور = الصلاحية) ومحتوى الوجهة.
//

import SwiftUI

struct TeamUserFormSheet: View {
    @State var draft: TeamUserDraft
    let onSave: (TeamUserDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_team_new" : "mrasem_admin_form_team_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_team_delete_title",
                                messageKey: "mrasem_admin_form_team_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.name, label: mrasemString("mrasem_admin_field_name"))
            ValueSelect(label: mrasemString("mrasem_admin_field_role"), values: TeamRole.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.role)
            MrasemTextField(value: $draft.phone, label: mrasemString("mrasem_admin_field_phone"), ltr: true)
            MrasemTextField(value: $draft.email, label: mrasemString("mrasem_admin_field_email"), ltr: true)
        }
    }
}

struct DestinationFormSheet: View {
    @State var draft: DestinationDraft
    let onSave: (DestinationDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_dest_new" : "mrasem_admin_form_dest_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_dest_delete_title",
                                messageKey: "mrasem_admin_form_dest_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.name, label: mrasemString("mrasem_admin_field_name"))
            ValueSelect(label: mrasemString("mrasem_admin_field_mode"), values: MissionMode.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.mode)
            MrasemTextField(value: $draft.timeZone, label: mrasemString("mrasem_admin_field_timezone"), ltr: true)
            MrasemTextField(value: $draft.currency, label: mrasemString("mrasem_admin_field_currency"))
            MrasemTextField(value: $draft.weather, label: mrasemString("mrasem_admin_field_weather"))
            MrasemTextField(value: $draft.emergency, label: mrasemString("mrasem_admin_field_emergency"), singleLine: false)
            MrasemTextField(value: $draft.quickInfo, label: mrasemString("mrasem_admin_field_quick_info"), singleLine: false)
            MrasemTextField(value: $draft.customs, label: mrasemString("mrasem_admin_field_customs"), singleLine: false)
            MrasemTextField(value: $draft.checklist, label: mrasemString("mrasem_admin_field_checklist"), singleLine: false)
            MrasemTextField(value: $draft.guides, label: mrasemString("mrasem_admin_field_guides"), singleLine: false)
        }
    }
}
