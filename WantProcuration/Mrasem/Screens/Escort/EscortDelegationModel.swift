//
//  EscortDelegationModel.swift
//  Mrasem
//
//  Phase 16 — «وفدي» للمرافق: بيتحدّث لحظياً مع أي تعديل في القاعدة.
//

import Foundation
import Combine

final class EscortDelegationModel: ObservableObject {
    @Published private(set) var uiState: EscortHomeState

    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend) {
        let today = backend.today
        uiState = Self.state(backend.database, today: today().iso)

        backend.store.publisher
            .map { Self.state($0, today: today().iso) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    private static func state(_ db: MrasemDatabase, today: String) -> EscortHomeState {
        guard case let .escort(id)? = db.currentUser else { return .empty }
        return .make(db, escortId: id, today: today)
    }
}
