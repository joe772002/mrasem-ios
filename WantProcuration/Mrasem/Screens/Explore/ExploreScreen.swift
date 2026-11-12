//
//  ExploreScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/explore/ExploreScreen.kt
//

import SwiftUI

/// تاب «استكشف» للضيف (01-DESIGN-SPEC §7.4).
struct ExploreScreen: View {
    @StateObject private var viewModel: ExploreViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: ExploreViewModel(
            session: context.container.session,
            explore: context.container.explore,
            toastBus: context.toastBus
        ))
    }

    var body: some View {
        ExploreContent(
            state: viewModel.uiState,
            onFilterSelected: viewModel.onFilterSelected,
            onRequestVisit: viewModel.onRequestVisit
        )
    }
}

struct ExploreContent: View {
    @Environment(\.mrasem) private var theme

    let state: ExploreUiState
    let onFilterSelected: (Int) -> Void
    let onRequestVisit: (String) -> Void

    var body: some View {
        MrasemScreenContent {
            MrasemNoticesSection(notices: state.notices)

            // كارت «حول الفندق»: العنوان + نص الترتيب + فلاتر الوقت المتاح.
            ExploreHeaderCard(
                hotelName: state.hotelName,
                filters: state.filters,
                selectedFilterIndex: state.selectedFilterIndex,
                onFilterSelected: onFilterSelected
            )

            // كروت الأماكن مرتبة تصاعدياً بزمن الوصول.
            ForEach(state.items, id: \.placeName) { item in
                ExplorePlaceCard(item: item, onRequestVisit: onRequestVisit)
            }

            Text(mrasemString("mrasem_explore_footer"))
                .mrasemText(theme.type.caption)
                .foregroundColor(theme.colors.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }
}

/// كارت «حول {الفندق}»: العنوان + شرح الترتيب + شريط الفلاتر.
private struct ExploreHeaderCard: View {
    @Environment(\.mrasem) private var theme

    let hotelName: String
    let filters: [ExploreFilter]
    let selectedFilterIndex: Int
    let onFilterSelected: (Int) -> Void

    var body: some View {
        MrasemCard(title: mrasemString("mrasem_explore_about_hotel", [hotelName])) {
            Text(mrasemString("mrasem_explore_sort_by"))
                .mrasemText(theme.type.body)
                .foregroundColor(theme.colors.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                        MrasemChip(
                            mrasemString(Self.labelKey(filter)),
                            selected: index == selectedFilterIndex
                        ) { onFilterSelected(index) }
                    }
                }
            }
        }
    }

    /// مفتاح اسم الفلتر في الـ catalog (قاعدة C1).
    static func labelKey(_ filter: ExploreFilter) -> String {
        switch filter {
        case .all: return "mrasem_explore_filter_all"
        case .oneHour: return "mrasem_explore_filter_1h"
        case .twoHours: return "mrasem_explore_filter_2h"
        case .halfDay: return "mrasem_explore_filter_half_day"
        case .fullDay: return "mrasem_explore_filter_full_day"
        }
    }
}

/// بطاقة مكان: العنوان + pill + الوصف + الميتا + زر «أرغب في الزيارة».
private struct ExplorePlaceCard: View {
    let item: ExploreItemUi
    let onRequestVisit: (String) -> Void

    var body: some View {
        let minutesText = item.minutes.toArabicDigits()
        let durationText = String(item.durationHours).toArabicDigits()
        let plural = item.durationHours > 2

        MrasemPlaceCard(
            name: item.placeName,
            tag: item.tag,
            description: item.description,
            meta: [
                mrasemString("mrasem_explore_meta_minutes", [minutesText]),
                mrasemString(plural ? "mrasem_explore_meta_duration_hours" : "mrasem_explore_meta_duration_hour", [durationText]),
                mrasemString("mrasem_explore_meta_vip"),
            ],
            actionLabel: mrasemString(Self.actionKey(item.requestState)),
            actionEnabled: item.requestState == .available,
            onAction: { onRequestVisit(item.placeName) }
        )
    }

    static func actionKey(_ state: PlaceRequestState) -> String {
        switch state {
        case .available: return "mrasem_explore_action_visit"
        case .pending: return "mrasem_explore_action_pending"
        case .arranged: return "mrasem_explore_action_arranged"
        }
    }
}

// MARK: - Previews

private enum ExplorePreviewData {
    static func state(_ mode: MissionMode, filter: ExploreFilter, pendingFirst: Bool = false) -> ExploreUiState {
        let repo = InMemoryMissionRepository(missions: MrasemDemoData.missions)
        let explore = ExploreStrategy(repository: repo)
        if pendingFirst, let first = explore.items().first {
            _ = explore.requestVisit(first.place.name)
        }
        var state = repo.state
        state.mode = mode
        state.filter = filter
        return ExploreUiState.make(state, explore: explore)
    }
}

#Preview("Explore inbound - Light") {
    MrasemScreenPreview(.light) {
        ExploreContent(state: ExplorePreviewData.state(.inbound, filter: .all, pendingFirst: true), onFilterSelected: { _ in }, onRequestVisit: { _ in })
    }
}

#Preview("Explore inbound - Dark") {
    MrasemScreenPreview(.dark) {
        ExploreContent(state: ExplorePreviewData.state(.inbound, filter: .all, pendingFirst: true), onFilterSelected: { _ in }, onRequestVisit: { _ in })
    }
}

#Preview("Explore outbound 2h - Light") {
    MrasemScreenPreview(.light) {
        ExploreContent(state: ExplorePreviewData.state(.outbound, filter: .twoHours), onFilterSelected: { _ in }, onRequestVisit: { _ in })
    }
}
