//
//  AdminResourcesScreen.swift
//  Mrasem
//
//  Phase 15 — تاب «الموارد» للأدمن (البوابة: السائقون والسيارات والمرافقون): قوائم بإضافة وتعديل،
//  جدول التعيينات، وبطاقة التعارضات مع حلها بتغيير السيارة.
//

import SwiftUI

struct AdminResourcesScreen: View {
    @StateObject private var model: AdminResourcesModel

    @State private var section: ResourceSection = .drivers
    @State private var driver: DriverDraft?
    @State private var car: CarDraft?
    @State private var escort: EscortDraft?
    @State private var resolving: AdminConflictSide?

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: AdminResourcesModel(backend: context.backend, toastBus: context.toastBus))
    }

    var body: some View {
        AdminResourcesContent(
            state: model.uiState,
            section: $section,
            onAddDriver: { driver = DriverDraft() },
            onEditDriver: { driver = model.draft(driver: $0) },
            onToggleDriver: model.toggleStatus,
            onAddCar: { car = CarDraft() },
            onEditCar: { car = model.draft(car: $0) },
            onAddEscort: { escort = EscortDraft() },
            onEditEscort: { escort = model.draft(escort: $0) },
            onResolve: { resolving = $0 }
        )
        .sheet(item: $driver) { draft in
            DriverFormSheet(draft: draft, onSave: model.save, onDelete: draft.isNew ? nil : { model.deleteDriver(draft.id) })
        }
        .sheet(item: $car) { draft in
            CarFormSheet(draft: draft, drivers: model.driverOptions(), onSave: model.save,
                         onDelete: draft.isNew ? nil : { model.deleteCar(draft.id) })
        }
        .sheet(item: $escort) { draft in
            EscortFormSheet(draft: draft, onSave: model.save, onDelete: draft.isNew ? nil : { model.deleteEscort(draft.id) })
        }
        .sheet(item: $resolving) { side in
            ConflictResolveSheet(
                side: side, cars: model.alternatives(forItem: side.itemId),
                onPick: { model.resolve(itemId: side.itemId, carId: $0) }
            )
        }
    }
}

struct AdminResourcesContent: View {
    @Environment(\.mrasem) private var theme

    let state: AdminResourcesState
    @Binding var section: ResourceSection
    let onAddDriver: () -> Void
    let onEditDriver: (String) -> Void
    let onToggleDriver: (String) -> Void
    let onAddCar: () -> Void
    let onEditCar: (String) -> Void
    let onAddEscort: () -> Void
    let onEditEscort: (String) -> Void
    let onResolve: (AdminConflictSide) -> Void

    var body: some View {
        MrasemScreenContent {
            Text("mrasem_admin_res_title")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)
                .accessibilityAddTraits(.isHeader)

            if !state.conflicts.isEmpty {
                conflictsCard
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ResourceSection.allCases, id: \.self) { item in
                        MrasemChip(mrasemString(item.titleKey), selected: item == section) { section = item }
                    }
                }
            }

            switch section {
            case .drivers: drivers
            case .cars: cars
            case .escorts: escorts
            case .schedule: schedule
            }
        }
    }

    // MARK: - التعارضات

    private var conflictsCard: some View {
        MrasemCard(title: mrasemString("mrasem_admin_conflicts_title")) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(state.conflicts) { conflict in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(mrasemString("mrasem_admin_conflict_text", [
                            conflict.driverName,
                            conflict.first.time.toArabicDigits(), conflict.first.delegationName,
                            conflict.second.time.toArabicDigits(), conflict.second.delegationName
                        ]))
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.ink)

                        ForEach([conflict.first, conflict.second]) { side in
                            MrasemButton(
                                mrasemString("mrasem_admin_conflict_change", [side.time.toArabicDigits(), side.title]),
                                variant: .outline, block: true
                            ) { onResolve(side) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - الأقسام

    @ViewBuilder
    private var drivers: some View {
        MrasemButton(mrasemString("mrasem_admin_res_add_driver"), variant: .primary, block: true, action: onAddDriver)
        if state.drivers.isEmpty {
            empty
        }
        ForEach(state.drivers) { row in
            MrasemActionRow(
                title: row.name,
                subtitle: mrasemString("mrasem_admin_res_driver_subtitle", [
                    row.phone.toArabicDigits(),
                    row.carLabel ?? mrasemString("mrasem_admin_res_no_car"),
                    row.tripsToday.toArabicDigits()
                ])
            ) {
                MrasemButton(mrasemString(row.status.adminLabelKey), variant: .outline) { onToggleDriver(row.id) }
            }
            .contentShape(Rectangle())
            .onTapGesture { onEditDriver(row.id) }
            // الصف فيه زر الحالة، فالتعديل بيبقى «إجراء» لـ VoiceOver بدل ما الصف كله يبقى زر.
            .accessibilityAction(named: Text(mrasemString("mrasem_admin_detail_edit"))) { onEditDriver(row.id) }
        }
    }

    @ViewBuilder
    private var cars: some View {
        MrasemButton(mrasemString("mrasem_admin_res_add_car"), variant: .primary, block: true, action: onAddCar)
        if state.cars.isEmpty {
            empty
        }
        ForEach(state.cars) { row in
            MrasemActionRow(
                title: row.type,
                subtitle: mrasemString("mrasem_admin_res_car_subtitle", [
                    row.plate.toArabicDigits(), row.driverName ?? mrasemString("mrasem_admin_res_no_driver")
                ])
            ) {
                MrasemPill(mrasemString("mrasem_admin_res_trips", [row.tripCount.toArabicDigits()]), kind: .neutral)
            }
            .contentShape(Rectangle())
            .onTapGesture { onEditCar(row.id) }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        }
    }

    @ViewBuilder
    private var escorts: some View {
        MrasemButton(mrasemString("mrasem_admin_res_add_escort"), variant: .primary, block: true, action: onAddEscort)
        if state.escorts.isEmpty {
            empty
        }
        ForEach(state.escorts) { row in
            MrasemActionRow(
                title: row.name,
                subtitle: mrasemString("mrasem_admin_res_escort_subtitle", [row.title, row.phone.toArabicDigits()])
            ) {
                MrasemPill(mrasemString("mrasem_admin_res_escort_count", [row.delegationNames.count.toArabicDigits()]), kind: .neutral)
            }
            .contentShape(Rectangle())
            .onTapGesture { onEditEscort(row.id) }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        }
    }

    @ViewBuilder
    private var schedule: some View {
        if state.assignments.isEmpty {
            Text("mrasem_admin_res_schedule_empty")
                .mrasemText(theme.type.body)
                .foregroundColor(theme.colors.muted)
        }
        ForEach(state.assignments) { row in
            MrasemActionRow(
                title: mrasemString("mrasem_admin_res_assign_title", [StoreTime.dayLabel(row.date), row.time.toArabicDigits(), row.title]),
                subtitle: mrasemString("mrasem_admin_res_assign_subtitle", [
                    row.delegationName,
                    row.carLabel ?? mrasemString("mrasem_admin_res_no_car"),
                    row.driverName ?? mrasemString("mrasem_admin_res_no_driver")
                ])
            ) {
                if row.hasConflict {
                    MrasemPill(mrasemString("mrasem_admin_conflict_pill"), kind: .warn)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var empty: some View {
        Text("mrasem_admin_res_empty")
            .mrasemText(theme.type.body)
            .foregroundColor(theme.colors.muted)
    }
}

#Preview("Admin resources - Light") {
    MrasemScreenPreview(.light) {
        AdminResourcesContent(
            state: .make(MrasemSeed.demo(), today: "2026-11-24"), section: .constant(.drivers),
            onAddDriver: {}, onEditDriver: { _ in }, onToggleDriver: { _ in }, onAddCar: {}, onEditCar: { _ in },
            onAddEscort: {}, onEditEscort: { _ in }, onResolve: { _ in }
        )
    }
}
