//
//  AdminResourceForms.swift
//  Mrasem
//
//  Phase 15 — نماذج السائق والسيارة والمرافق، وشاشة اختيار سيارة بديلة لحل التعارض.
//

import SwiftUI

struct DriverFormSheet: View {
    @State var draft: DriverDraft
    let onSave: (DriverDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_driver_new" : "mrasem_admin_form_driver_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_driver_delete_title",
                                messageKey: "mrasem_admin_form_driver_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.name, label: mrasemString("mrasem_admin_field_name"))
            MrasemTextField(value: $draft.phone, label: mrasemString("mrasem_admin_field_phone"), ltr: true)
            ValueSelect(label: mrasemString("mrasem_admin_field_status"), values: DriverStatus.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.status)
        }
    }
}

struct CarFormSheet: View {
    @State var draft: CarDraft
    let drivers: [PickerOption]
    let onSave: (CarDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_car_new" : "mrasem_admin_form_car_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_car_delete_title",
                                messageKey: "mrasem_admin_form_car_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.type, label: mrasemString("mrasem_admin_field_car_type"))
            MrasemTextField(value: $draft.plate, label: mrasemString("mrasem_admin_field_plate"), ltr: true)
            ValueSelect(label: mrasemString("mrasem_admin_field_plate_style"), values: PlateStyle.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.plateStyle)
            IdSelect(label: mrasemString("mrasem_admin_field_driver"), options: drivers, selection: $draft.driverId)
        }
    }
}

struct EscortFormSheet: View {
    @State var draft: EscortDraft
    let onSave: (EscortDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_escort_new" : "mrasem_admin_form_escort_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_escort_delete_title",
                                messageKey: "mrasem_admin_form_escort_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.name, label: mrasemString("mrasem_admin_field_name"))
            MrasemTextField(value: $draft.title, label: mrasemString("mrasem_admin_field_title"))
            MrasemTextField(value: $draft.phone, label: mrasemString("mrasem_admin_field_phone"), ltr: true)
            MrasemTextField(value: $draft.meetingSpot, label: mrasemString("mrasem_admin_field_meeting_spot"))
        }
    }
}

/// فقرة بتتعارض: السواق مشغول في وفد تاني. الأدمن بيختار سيارة سواقها فاضي.
struct ConflictResolveSheet: View {
    @Environment(\.mrasem) private var theme
    @Environment(\.dismiss) private var dismiss

    let side: AdminConflictSide
    let cars: [CarRecord]
    let onPick: (String) -> Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                Text(mrasemString("mrasem_admin_conflict_resolve_title", [side.title]))
                    .mrasemText(theme.type.cardTitle)
                    .foregroundColor(theme.colors.maroon)
                    .accessibilityAddTraits(.isHeader)

                if cars.isEmpty {
                    Text("mrasem_admin_conflict_no_alternative")
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.muted)
                } else {
                    ForEach(cars) { car in
                        MrasemActionRow(title: AdminDelegationDetailBuilder.carLabel(car) ?? car.id, subtitle: car.plate)
                            .contentShape(Rectangle())
                            .onTapGesture { if onPick(car.id) { dismiss() } }
                            .accessibilityAddTraits(.isButton)
                    }
                }

                MrasemButton(mrasemString("mrasem_admin_form_cancel"), variant: .ghost, block: true) { dismiss() }
            }
            .padding(theme.dimens.screenHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.bg.ignoresSafeArea())
    }
}

extension AdminConflictSide: Identifiable {
    var id: String { itemId }
}
