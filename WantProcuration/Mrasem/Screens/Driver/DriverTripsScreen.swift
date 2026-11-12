//
//  DriverTripsScreen.swift
//  Mrasem
//
//  Phase 16 — «رحلاتي» للسائق: رحلات النهاردة بحالتها وزر الخطوة الجاية، وتنبيهاته.
//

import SwiftUI

struct DriverTripsScreen: View {
    @StateObject private var model: DriverTripsModel

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: DriverTripsModel(backend: context.backend))
    }

    var body: some View {
        DriverTripsContent(
            state: model.uiState, notices: model.notices,
            onAdvance: model.advance, onMarkRead: model.markNoticesRead
        )
    }
}

struct DriverTripsContent: View {
    @Environment(\.mrasem) private var theme

    let state: DriverHomeState
    let notices: NoticeInboxState
    let onAdvance: (String) -> Void
    let onMarkRead: () -> Void

    var body: some View {
        MrasemScreenContent {
            VStack(alignment: .leading, spacing: 4) {
                Text("mrasem_tab_driver_trips")
                    .mrasemText(theme.type.heroDest)
                    .foregroundColor(theme.colors.maroon)
                    .accessibilityAddTraits(.isHeader)
                Text(mrasemString("mrasem_driver_summary", [
                    StoreTime.dayLabel(state.date), state.done.toArabicDigits(), state.rows.count.toArabicDigits(),
                    state.carLabel ?? mrasemString("mrasem_admin_res_no_car")
                ]))
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.muted)
            }

            if state.rows.isEmpty {
                Text("mrasem_driver_empty_today")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            }
            ForEach(state.rows) { row in
                DriverTripCard(row: row, onAdvance: { onAdvance(row.id) })
            }

            NoticeInboxCard(state: notices, onMarkRead: onMarkRead)
        }
    }
}

/// بطاقة رحلة: الوقت والمسار والركّاب وحالة الرحلة.
struct DriverTripCard: View {
    @Environment(\.mrasem) private var theme

    let row: DriverTripRow
    let onAdvance: (() -> Void)?

    var body: some View {
        MrasemCard(
            title: mrasemString("mrasem_driver_trip_title", [row.time.toArabicDigits(), row.title]),
            headerEnd: AnyView(MrasemPill(
                mrasemString(row.status.driverLabelKey),
                kind: row.status == .completed ? .ok : (row.status == .scheduled ? .neutral : .warn)
            ))
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text(row.delegationName)
                    .mrasemText(theme.type.strong)
                    .foregroundColor(theme.colors.ink)
                MrasemKeyValueList([
                    KeyValue(mrasemString("mrasem_driver_kv_pickup"), row.pickupTime.toArabicDigits()),
                    KeyValue(mrasemString("mrasem_driver_kv_arrival"), row.arrivalTime.toArabicDigits()),
                    KeyValue(mrasemString("mrasem_driver_kv_from"), row.from.isEmpty ? "—" : row.from),
                    KeyValue(mrasemString("mrasem_driver_kv_to"), row.to),
                    KeyValue(mrasemString("mrasem_driver_kv_passengers"), row.passengers.joined(separator: "، ")),
                    KeyValue(mrasemString("mrasem_driver_kv_escorts"), row.escorts.isEmpty ? "—" : row.escorts.joined(separator: "، "))
                ])
                if let onAdvance, let next = row.next {
                    MrasemButton(mrasemString(next.driverActionKey), variant: .primary, block: true, action: onAdvance)
                }
            }
        }
    }
}

#Preview("Driver trips - Light") {
    MrasemScreenPreview(.light) {
        DriverTripsContent(
            state: .make(MrasemSeed.demo(), driverId: "r1", today: "2026-11-24"),
            notices: .empty, onAdvance: { _ in }, onMarkRead: {}
        )
    }
}
