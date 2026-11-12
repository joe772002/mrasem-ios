//
//  PlanScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/plan/PlanScreen.kt
//

import SwiftUI

/// تاب «البرنامج» للضيف (01-DESIGN-SPEC §7.2).
struct PlanScreen: View {
    @StateObject private var viewModel: PlanViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: PlanViewModel(
            session: context.container.session,
            program: context.container.program
        ))
    }

    var body: some View {
        PlanContent(
            state: viewModel.uiState,
            onDaySelected: viewModel.onDaySelected,
            onKeyCardClick: viewModel.onKeyCardClick,
            onFreeTimeSuggestionClick: viewModel.onFreeTimeSuggestionClick
        )
    }
}

struct PlanContent: View {
    @Environment(\.mrasem) private var theme

    let state: PlanUiState
    let onDaySelected: (Int) -> Void
    let onKeyCardClick: () -> Void
    let onFreeTimeSuggestionClick: () -> Void

    var body: some View {
        let entries = state.timeline.entries

        MrasemScreenContent {
            MrasemNoticesSection(notices: state.notices)
            MrasemDayTabs(
                labels: state.dayLabels,
                selectedIndex: Binding(get: { state.timeline.dayIndex }, set: { onDaySelected($0) })
            )
            MrasemCard(
                title: mrasemString("mrasem_plan_title"),
                headerEnd: AnyView(
                    Text(state.timeZone)
                        .mrasemText(theme.type.label)
                        .foregroundColor(theme.colors.muted)
                )
            ) {
                // عمود واحد = من غير gap بين الفقرات (الفواصل جزء من كل فقرة).
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { i, entry in
                        entryView(entry, isLast: i == entries.count - 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func entryView(_ entry: TimelineEntry, isLast: Bool) -> some View {
        switch entry {
        case let .official(_, item, changed):
            MrasemTimelineItem(
                time: item.time,
                title: item.title,
                place: item.place,
                note: item.note,
                changed: changed,
                changedLabel: mrasemString("mrasem_plan_changed"),
                keyCardLabel: item.isKey ? mrasemString("mrasem_plan_key_card") : nil,
                onKeyCardClick: onKeyCardClick,
                showDivider: !isLast
            )
        case let .freeTime(item, suggestions):
            MrasemFreeTimeItem(
                from: item.from,
                title: mrasemString("mrasem_plan_free_until", [item.to]),
                description: mrasemString("mrasem_plan_free_hours", [item.hours.toArabicNumber()]),
                suggestions: suggestions.map(\.name),
                onSuggestion: { _ in onFreeTimeSuggestionClick() }
            )
        }
    }
}

// MARK: - Previews

private enum PlanPreviewData {
    static func state(inbound: Bool, dayIndex: Int, withNotice: Bool = false) -> PlanUiState {
        let mission = inbound ? MrasemDemoData.inbound : MrasemDemoData.outbound
        let entries = mission.days[dayIndex].items.enumerated().map { index, item -> TimelineEntry in
            switch item {
            case let .official(official):
                return .official(index: index, item: official, changed: withNotice && official.isKey)
            case let .freeTime(freeTime):
                return .freeTime(item: freeTime, suggestions: ProgramStrategy.suggestions(mission.places, hours: freeTime.hours))
            }
        }
        return PlanUiState(
            notices: withNotice
                ? [Notice(id: 1, mode: mission.mode, content: .postponed(title: "جلسة المباحثات الرسمية", newTime: "10:00"))]
                : [],
            timeZone: mission.timeZone,
            dayLabels: mission.days.map(\.label),
            timeline: DayTimeline(dayIndex: dayIndex, entries: entries)
        )
    }

    static let inbound = state(inbound: true, dayIndex: 1, withNotice: true)
    static let outbound = state(inbound: false, dayIndex: 0)
}

#Preview("Plan inbound - Light") {
    MrasemScreenPreview(.light) { PlanContent(state: PlanPreviewData.inbound, onDaySelected: { _ in }, onKeyCardClick: {}, onFreeTimeSuggestionClick: {}) }
}

#Preview("Plan inbound - Dark") {
    MrasemScreenPreview(.dark) { PlanContent(state: PlanPreviewData.inbound, onDaySelected: { _ in }, onKeyCardClick: {}, onFreeTimeSuggestionClick: {}) }
}

#Preview("Plan outbound - Light") {
    MrasemScreenPreview(.light) { PlanContent(state: PlanPreviewData.outbound, onDaySelected: { _ in }, onKeyCardClick: {}, onFreeTimeSuggestionClick: {}) }
}
