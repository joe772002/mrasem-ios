//
//  ExploreStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/ExploreStrategy.kt
//

import Foundation

/// حالة زر المكان: «أرغب في الزيارة» / «أُرسل الطلب لمنسق المراسم» / «تم الترتيب».
enum PlaceRequestState: Equatable {
    case available
    case pending
    case arranged
}

struct PlaceItem: Equatable {
    let place: Place
    let requestState: PlaceRequestState
    /// «ساعات» لو المدة > ٢، غير كده «ساعة».
    let pluralHours: Bool
}

nonisolated final class ExploreStrategy {
    private let repository: MissionRepository

    init(repository: MissionRepository) {
        self.repository = repository
    }

    func items(state: MrasemState? = nil) -> [PlaceItem] {
        let state = state ?? repository.state
        return Self.filterPlaces(state.mission.places, filter: state.filter).map { place in
            PlaceItem(
                place: place,
                requestState: Self.requestState(state, placeName: place.name),
                pluralHours: place.durationHours > 2
            )
        }
    }

    /// ينشئ طلب زيارة. يرجّع false لو المكان مطلوب قبل كده في نفس الوضع.
    func requestVisit(_ placeName: String) -> Bool {
        let state = repository.state
        guard Self.requestState(state, placeName: placeName) == .available else { return false }
        repository.addRequest(mode: state.mode, kind: .visit, place: placeName, text: nil)
        return true
    }

    static func fits(_ place: Place, filter: ExploreFilter) -> Bool {
        switch filter {
        case .all, .fullDay: return true
        case .oneHour: return place.durationHours <= 1
        case .twoHours: return place.durationHours <= 2
        case .halfDay: return place.durationHours <= 4
        }
    }

    /// مفلترة ومرتبة تصاعدياً بزمن الوصول.
    static func filterPlaces(_ places: [Place], filter: ExploreFilter) -> [Place] {
        places
            .filter { fits($0, filter: filter) }
            .sorted { $0.minutes < $1.minutes }
    }

    static func requestState(_ state: MrasemState, placeName: String) -> PlaceRequestState {
        guard let request = state.requests(for: state.mode).first(where: { $0.place == placeName }) else {
            return .available
        }
        return request.status == .done ? .arranged : .pending
    }
}
