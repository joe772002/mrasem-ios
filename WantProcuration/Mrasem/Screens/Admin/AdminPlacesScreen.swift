//
//  AdminPlacesScreen.swift
//  Mrasem
//
//  Phase 15 — تاب «الأماكن» للأدمن (البوابة: الأماكن والجهات): قائمة بفلتر النوع، وإضافة وتعديل وحذف بتأكيد.
//

import SwiftUI

struct AdminPlacesScreen: View {
    @StateObject private var model: AdminPlacesModel
    @State private var editing: PlaceDraft?

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: AdminPlacesModel(backend: context.backend, toastBus: context.toastBus))
    }

    var body: some View {
        AdminPlacesContent(
            state: model.uiState,
            onFilter: model.onFilter,
            onAdd: { editing = model.newDraft() },
            onEdit: { editing = model.draft(place: $0) }
        )
        .sheet(item: $editing) { draft in
            PlaceFormSheet(draft: draft, onSave: model.save, onDelete: draft.isNew ? nil : { model.delete(draft.id) })
        }
    }
}

struct AdminPlacesContent: View {
    @Environment(\.mrasem) private var theme

    let state: AdminPlacesState
    let onFilter: (PlaceFilter) -> Void
    let onAdd: () -> Void
    let onEdit: (String) -> Void

    var body: some View {
        MrasemScreenContent {
            Text("mrasem_admin_places_title")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)
                .accessibilityAddTraits(.isHeader)

            MrasemButton(mrasemString("mrasem_admin_places_add"), variant: .primary, block: true, action: onAdd)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PlaceFilter.allCases, id: \.self) { filter in
                        MrasemChip(
                            mrasemString("mrasem_admin_filter_count", [
                                mrasemString(filter.titleKey), (state.counts[filter] ?? 0).toArabicDigits()
                            ]),
                            selected: filter == state.filter
                        ) { onFilter(filter) }
                    }
                }
            }

            if state.rows.isEmpty {
                Text("mrasem_admin_places_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            }

            ForEach(state.rows) { row in
                MrasemActionRow(
                    title: row.name,
                    subtitle: row.description.isEmpty ? mrasemString(row.mode.adminLabelKey) : row.description
                ) {
                    MrasemPill(mrasemString(row.kind.adminLabelKey), kind: .neutral)
                }
                .contentShape(Rectangle())
                .onTapGesture { onEdit(row.id) }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
    }
}

struct PlaceFormSheet: View {
    @State var draft: PlaceDraft
    let onSave: (PlaceDraft) -> String?
    let onDelete: (() -> Void)?

    var body: some View {
        AdminFormSheet(
            titleKey: draft.isNew ? "mrasem_admin_form_place_new" : "mrasem_admin_form_place_edit",
            onSave: { onSave(draft) },
            delete: onDelete.map {
                AdminFormDelete(titleKey: "mrasem_admin_form_place_delete_title",
                                messageKey: "mrasem_admin_form_place_delete_message", action: $0)
            }
        ) {
            MrasemTextField(value: $draft.name, label: mrasemString("mrasem_admin_field_name"))
            ValueSelect(label: mrasemString("mrasem_admin_field_place_kind"), values: PlaceKind.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.kind)
            ValueSelect(label: mrasemString("mrasem_admin_field_mode"), values: MissionMode.allCases,
                        title: { mrasemString($0.adminLabelKey) }, selection: $draft.mode)
            MrasemTextField(value: $draft.description, label: mrasemString("mrasem_admin_field_description"), singleLine: false)
            MrasemTextField(value: $draft.area, label: mrasemString("mrasem_admin_field_area"))
            MrasemTextField(value: $draft.minutes, label: mrasemString("mrasem_admin_field_minutes"), ltr: true)
            MrasemTextField(value: $draft.phone, label: mrasemString("mrasem_admin_field_phone"), ltr: true)
            MrasemTextField(value: $draft.mapLabel, label: mrasemString("mrasem_admin_field_map_label"))
            MrasemTextField(value: $draft.tag, label: mrasemString("mrasem_admin_field_tag"))

            switch draft.kind {
            case .hotel:
                MrasemTextField(value: $draft.breakfast, label: mrasemString("mrasem_admin_field_breakfast"))
            case .entity:
                entityFields
            case .attraction:
                MrasemTextField(value: $draft.durationHours, label: mrasemString("mrasem_admin_field_duration"), ltr: true)
            case .restaurant:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var entityFields: some View {
        MrasemTextField(value: $draft.official, label: mrasemString("mrasem_admin_field_official"))
        MrasemTextField(value: $draft.building, label: mrasemString("mrasem_admin_field_building"))
        MrasemTextField(value: $draft.entrance, label: mrasemString("mrasem_admin_field_entrance"))
        MrasemTextField(value: $draft.floor, label: mrasemString("mrasem_admin_field_floor"))
        MrasemTextField(value: $draft.hall, label: mrasemString("mrasem_admin_field_hall"))
        MrasemTextField(value: $draft.parking, label: mrasemString("mrasem_admin_field_parking"))
    }
}

#Preview("Admin places - Light") {
    MrasemScreenPreview(.light) {
        AdminPlacesContent(
            state: .make(MrasemSeed.demo(), filter: .all), onFilter: { _ in }, onAdd: {}, onEdit: { _ in }
        )
    }
}
