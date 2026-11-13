//
//  AdminForms.swift
//  Mrasem
//
//  Phase 14 — نماذج الأدمن: الوفد، العضو، فقرة البرنامج. كلها بتكتب في المسوّدة وبترجّع مفتاح الخطأ من الـ service.
//

import SwiftUI

struct DelegationFormSheet: View {
    @State var draft: DelegationDraft
    let hotels: [PickerOption]
    let venues: [PickerOption]
    let onSave: (DelegationDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_delegation_new" : "mrasem_admin_form_delegation_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_delegation_delete_title",
                      messageKey: "mrasem_admin_form_delegation_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.name, label: mrasemString("mrasem_admin_field_name"))
            ValueSelect(label: mrasemString("mrasem_admin_field_mode"), values: MissionMode.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.mode)
            MrasemTextField(value: $draft.host, label: mrasemString("mrasem_admin_field_host"))
            MrasemTextField(value: $draft.countryLabel, label: mrasemString("mrasem_admin_field_country"))
            MrasemTextField(value: $draft.start, label: mrasemString("mrasem_admin_field_start"), placeholder: "2026-11-23", ltr: true)
            MrasemTextField(value: $draft.end, label: mrasemString("mrasem_admin_field_end"), placeholder: "2026-11-25", ltr: true)
            IdSelect(label: mrasemString("mrasem_admin_field_hotel"), options: hotels, selection: $draft.hotelId)
            IdSelect(label: mrasemString("mrasem_admin_field_venue"), options: venues, selection: $draft.venueId)
            ValueSelect(label: mrasemString("mrasem_team_field_dress"), values: DressCode.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.dress)
            ValueSelect(label: mrasemString("mrasem_admin_field_status"), values: DelegationStatus.allCases,
                        title: { mrasemString($0.labelKey) }, selection: $draft.status)
        }
    }
}

struct MemberFormSheet: View {
    @State var draft: MemberDraft
    let escorts: [PickerOption]
    let cars: [PickerOption]
    let onSave: (MemberDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_member_new" : "mrasem_admin_form_member_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_member_delete_title",
                      messageKey: "mrasem_admin_form_member_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.name, label: mrasemString("mrasem_admin_field_name"))
            MrasemTextField(value: $draft.title, label: mrasemString("mrasem_admin_field_title"))
            MrasemTextField(value: $draft.room, label: mrasemString("mrasem_admin_field_room"))
            IdSelect(label: mrasemString("mrasem_admin_field_escort"), options: escorts, selection: $draft.escortId)
            IdSelect(label: mrasemString("mrasem_admin_field_car"), options: cars, selection: $draft.carId)
            AdminToggleRow(label: mrasemString("mrasem_admin_field_activated"), isOn: $draft.isActivated)
            AdminToggleRow(label: mrasemString("mrasem_admin_field_head"), isOn: $draft.isHead)
        }
    }
}

struct ProgramFormSheet: View {
    @State var draft: ProgramDraft
    let days: [String]
    let places: [PickerOption]
    let cars: [PickerOption]
    let onSave: (ProgramDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_item_new" : "mrasem_admin_form_item_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_item_delete_title",
                      messageKey: "mrasem_admin_form_item_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.title, label: mrasemString("mrasem_admin_field_item_title"))
            ValueSelect(label: mrasemString("mrasem_admin_field_day"), values: dayChoices,
                        title: { StoreTime.dayLabel($0) }, selection: $draft.date)
            MrasemTextField(value: $draft.time, label: mrasemString("mrasem_admin_field_time"), placeholder: "09:00", ltr: true)
            ValueSelect(label: mrasemString("mrasem_admin_field_kind"), values: ProgramItemKind.allCases,
                        title: { mrasemString($0.labelKey) }, selection: $draft.kind)
            if draft.kind == .free {
                MrasemTextField(value: $draft.endTime, label: mrasemString("mrasem_admin_field_end_time"), placeholder: "10:00", ltr: true)
            }
            IdSelect(label: mrasemString("mrasem_admin_field_place"), options: places, selection: $draft.placeId)
            IdSelect(label: mrasemString("mrasem_admin_field_car"), options: cars, selection: $draft.carId)
            MrasemTextField(value: $draft.dressCode, label: mrasemString("mrasem_admin_field_dress_code"),
                            placeholder: mrasemString("mrasem_admin_field_dress_code_hint"))
            MrasemTextField(value: $draft.note, label: mrasemString("mrasem_admin_field_note"), singleLine: false)
            AdminToggleRow(label: mrasemString("mrasem_admin_field_key"), isOn: $draft.isKey)
            AdminToggleRow(label: mrasemString("mrasem_admin_field_notify"), isOn: $draft.notify)
        }
    }

    /// أيام الوفد، ولو تاريخ الفقرة خارجها (بيانات قديمة) بنضيفه عشان الاختيار يفضل صح.
    private var dayChoices: [String] {
        days.contains(draft.date) ? days : (days + [draft.date]).sorted()
    }
}

extension MissionMode {
    var adminLabelKey: String { "mrasem_admin_mode_" + rawValue }
}

extension DressCode {
    var adminLabelKey: String { self == .bisht ? "mrasem_dress_option_bisht" : "mrasem_dress_option_formal" }
}
