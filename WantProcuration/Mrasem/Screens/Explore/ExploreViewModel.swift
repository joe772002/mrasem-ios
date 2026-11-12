//
//  ExploreViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/explore/ExploreViewModel.kt
//

import Foundation
import Combine

struct ExploreItemUi: Equatable {
    let placeName: String
    let tag: String?
    let description: String
    let minutes: Int
    let durationHours: Double
    let requestState: PlaceRequestState
}

struct ExploreUiState: Equatable {
    let notices: [Notice]
    let hotelName: String
    let filters: [ExploreFilter]
    let selectedFilterIndex: Int
    let items: [ExploreItemUi]

    static func make(_ state: MrasemState, explore: ExploreStrategy) -> ExploreUiState {
        let filters = ExploreFilter.allCases
        return ExploreUiState(
            notices: state.recentNotices(),
            hotelName: state.mission.hotel.name,
            filters: filters,
            selectedFilterIndex: filters.firstIndex(of: state.filter) ?? 0,
            items: explore.items(state: state).map { item in
                ExploreItemUi(
                    placeName: item.place.name,
                    tag: item.place.tag,
                    description: item.place.description,
                    minutes: item.place.minutes,
                    durationHours: item.place.durationHours,
                    requestState: item.requestState
                )
            }
        )
    }
}

/// حالة شاشة استكشف (الضيف) (01-DESIGN-SPEC §7.4).
final class ExploreViewModel: ObservableObject {
    @Published private(set) var uiState: ExploreUiState

    private let session: MrasemSessionStrategy
    private let explore: ExploreStrategy
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, explore: ExploreStrategy, toastBus: MrasemToastBus) {
        self.session = session
        self.explore = explore
        self.toastBus = toastBus
        self.uiState = ExploreUiState.make(session.state, explore: explore)

        session.statePublisher
            .map { ExploreUiState.make($0, explore: explore) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    /// تغيير فلتر استكشف.
    func onFilterSelected(_ index: Int) {
        let filters = ExploreFilter.allCases
        guard filters.indices.contains(index) else { return }
        session.selectFilter(filters[index])
    }

    /// ضغط على زر المكان: ينشئ طلب زيارة ويعرض توست.
    func onRequestVisit(_ placeName: String) {
        guard explore.requestVisit(placeName) else { return }
        toastBus.show(ToastMessage(
            .res("mrasem_explore_toast_strong"),
            .res("mrasem_explore_toast_rest")
        ))
    }
}
