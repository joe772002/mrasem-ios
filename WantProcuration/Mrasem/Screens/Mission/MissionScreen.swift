//
//  MissionScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/mission/MissionScreen.kt
//  (الكروت الستة الأخيرة في MissionCards.swift عشان الملف ما يعديش ~300 سطر — قاعدة B8)
//

import SwiftUI

/// تاب «المهمة» للضيف (01-DESIGN-SPEC §7.1).
struct MissionScreen: View {
    @StateObject private var viewModel: MissionViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: MissionViewModel(
            session: context.container.session,
            summary: context.container.missionSummary,
            toastBus: context.toastBus
        ))
    }

    var body: some View {
        MissionContent(
            state: viewModel.uiState,
            onArrivalClick: viewModel.onArrivalClick,
            onCall: { ExternalLinks.dial($0) },
            onWhatsApp: { ExternalLinks.whatsApp($0) },
            onOpenMaps: { ExternalLinks.maps(lat: $0, lng: $1) }
        )
    }
}

struct MissionContent: View {
    let state: MissionUiState
    let onArrivalClick: () -> Void
    let onCall: (String) -> Void
    let onWhatsApp: (String) -> Void
    let onOpenMaps: (Double, Double) -> Void

    var body: some View {
        let mission = state.mission
        let summary = state.summary

        MrasemScreenContent {
            MrasemNoticesSection(notices: state.notices)
            MissionHero(mission: mission, summary: summary)
            ArrivalCard(mission: mission, summary: summary, onArrivalClick: onArrivalClick)
            ReceiverCard(
                mission: mission,
                updated: summary.changedSections.contains(.receiver),
                onCall: onCall,
                onWhatsApp: onWhatsApp
            )
            CarCard(mission: mission, updated: summary.changedSections.contains(.car))
            VenueCard(mission: mission, updated: summary.changedSections.contains(.venue), onOpenMaps: onOpenMaps)
            StayCard(mission: mission)
            PassCard(mission: mission)
            EmergencyCard(mission: mission)
        }
    }
}

private struct MissionHero: View {
    @Environment(\.mrasem) private var theme

    let mission: Mission
    let summary: MissionSummary

    var body: some View {
        MrasemHeroCard {
            HStack(alignment: .center, spacing: 12) {
                MrasemPill(mission.country)
                Text(mission.host)
                    .mrasemText(theme.type.label)
                    .foregroundColor(theme.colors.muted)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Text(mission.dest)
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.ink)
            Text(mission.guest)
                .mrasemText(theme.type.heroSub)
                .foregroundColor(theme.colors.muted)

            HStack(spacing: 8) {
                switch summary.countdown {
                case let .daysLeft(days):
                    MrasemStatTile(value: days.toArabicDigits(), label: mrasemString("mrasem_mission_stat_days_left"))
                case .today:
                    MrasemStatTile(
                        value: mrasemString("mrasem_mission_stat_today"),
                        label: mrasemString("mrasem_mission_stat_arrival_day")
                    )
                }
                MrasemStatTile(
                    value: summary.durationDays.toArabicDigits(),
                    label: mrasemString("mrasem_mission_stat_duration")
                )
                MrasemStatTile(
                    value: summary.officialCount.toArabicDigits(),
                    label: mrasemString("mrasem_mission_stat_official")
                )
            }

            MrasemKeyValueList([
                KeyValue(mrasemString("mrasem_mission_kv_timezone"), mission.timeZone),
                KeyValue(mrasemString("mrasem_mission_kv_currency"), mission.currency),
                KeyValue(mrasemString("mrasem_mission_kv_weather"), mission.weather),
            ])
        }
    }
}

private struct ArrivalCard: View {
    let mission: Mission
    let summary: MissionSummary
    let onArrivalClick: () -> Void

    var body: some View {
        let steps = [
            mrasemString("mrasem_arrival_step_landed"),
            mrasemString("mrasem_arrival_step_receiver", [mission.receiver.name, mission.receiver.spot]),
            mrasemString("mrasem_arrival_step_driver", [mission.car.driver]),
            mrasemString("mrasem_arrival_step_hotel"),
        ]

        MissionCard(
            title: mrasemString("mrasem_arrival_title"),
            headerEnd: summary.arrivalCompleted
                ? AnyView(MrasemPill(mrasemString("mrasem_pill_done"), kind: .ok))
                : nil
        ) {
            MrasemStatusSteps(steps: steps, current: summary.arrivalStage)
            MrasemButton(
                mrasemString(buttonKey),
                variant: .primary,
                block: true,
                enabled: !summary.arrivalCompleted,
                action: onArrivalClick
            )
        }
    }

    private var buttonKey: String {
        switch summary.button {
        case .notifyArrival: return "mrasem_arrival_button_notify"
        case .nextStep: return "mrasem_arrival_button_next"
        case .completed: return "mrasem_arrival_button_completed"
        }
    }
}

// MARK: - Previews

private enum MissionPreviewData {
    static func state(_ mission: Mission, stage: Int, updated: Set<ChangedSection> = []) -> MissionUiState {
        MissionUiState(
            notices: [],
            mission: mission,
            summary: MissionSummary(
                countdown: .daysLeft(12),
                durationDays: 3,
                officialCount: mission.officialCount,
                arrivalStage: stage,
                button: MissionSummaryStrategy.button(for: stage),
                changedSections: updated
            )
        )
    }

    static let inbound = state(MrasemDemoData.inbound, stage: 1, updated: [.receiver])
    static let outboundDone = state(MrasemDemoData.outbound, stage: 4, updated: [.car, .venue])
}

#Preview("Mission inbound - Light") {
    MrasemScreenPreview(.light) { MissionContent(state: MissionPreviewData.inbound, onArrivalClick: {}, onCall: { _ in }, onWhatsApp: { _ in }, onOpenMaps: { _, _ in }) }
}

#Preview("Mission inbound - Dark") {
    MrasemScreenPreview(.dark) { MissionContent(state: MissionPreviewData.inbound, onArrivalClick: {}, onCall: { _ in }, onWhatsApp: { _ in }, onOpenMaps: { _, _ in }) }
}

#Preview("Mission outbound done - Light") {
    MrasemScreenPreview(.light) { MissionContent(state: MissionPreviewData.outboundDone, onArrivalClick: {}, onCall: { _ in }, onWhatsApp: { _ in }, onOpenMaps: { _, _ in }) }
}
