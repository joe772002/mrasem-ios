//
//  DriverScheduleScreen.swift
//  Mrasem
//
//  Phase 16 — «الجدول» للسائق: كل رحلاته مجمّعة بالأيام (للقراءة).
//

import SwiftUI

struct DriverScheduleScreen: View {
    @StateObject private var model: DriverScheduleModel

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: DriverScheduleModel(backend: context.backend))
    }

    var body: some View {
        DriverScheduleContent(state: model.uiState)
    }
}

struct DriverScheduleContent: View {
    @Environment(\.mrasem) private var theme

    let state: DriverScheduleState

    var body: some View {
        MrasemScreenContent {
            Text("mrasem_tab_driver_schedule")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)
                .accessibilityAddTraits(.isHeader)

            if state.days.isEmpty {
                Text("mrasem_driver_empty_schedule")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            }
            ForEach(state.days) { day in
                Text(StoreTime.dayLabel(day.date))
                    .mrasemText(theme.type.cardTitle)
                    .foregroundColor(theme.colors.maroon)
                ForEach(day.rows) { row in
                    DriverTripCard(row: row, onAdvance: nil)
                }
            }
        }
    }
}

#Preview("Driver schedule - Light") {
    MrasemScreenPreview(.light) {
        DriverScheduleContent(state: .make(MrasemSeed.demo(), driverId: "r1"))
    }
}
