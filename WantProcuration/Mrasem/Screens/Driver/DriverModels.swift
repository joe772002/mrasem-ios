//
//  DriverModels.swift
//  Mrasem
//
//  Phase 16 — «رحلاتي» و«الجدول» للسائق. تغيير حالة الرحلة بيعدّي على `DriverTripService` فالتنبيه بيوصل للركّاب والمرافقين.
//

import Foundation
import Combine

final class DriverTripsModel: ObservableObject {
    @Published private(set) var uiState: DriverHomeState
    @Published private(set) var notices: NoticeInboxState

    private let backend: MrasemBackend
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend) {
        self.backend = backend
        let today = backend.today
        uiState = Self.state(backend.database, today: today().iso)
        notices = .make(backend.database, user: backend.database.currentUser)

        backend.store.publisher
            .sink { [weak self] db in
                guard let self else { return }
                let next = Self.state(db, today: today().iso)
                if next != self.uiState { self.uiState = next }
                let inbox = NoticeInboxState.make(db, user: db.currentUser)
                if inbox != self.notices { self.notices = inbox }
            }
            .store(in: &cancellables)
    }

    /// الخطوة الجاية في الرحلة («في الطريق» ← «وصلت» ← «تم الاستلام» ← «انتهت»).
    func advance(_ tripId: String) {
        guard let row = uiState.rows.first(where: { $0.id == tripId }), let next = row.next else { return }
        backend.trips.setStatus(tripId, next)
    }

    func markNoticesRead() {
        backend.markNoticesRead()
    }

    private static func state(_ db: MrasemDatabase, today: String) -> DriverHomeState {
        guard case let .driver(id)? = db.currentUser else { return .empty }
        return .make(db, driverId: id, today: today)
    }
}

final class DriverScheduleModel: ObservableObject {
    @Published private(set) var uiState: DriverScheduleState

    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend) {
        uiState = Self.state(backend.database)

        backend.store.publisher
            .map { Self.state($0) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    private static func state(_ db: MrasemDatabase) -> DriverScheduleState {
        guard case let .driver(id)? = db.currentUser else { return DriverScheduleState(days: []) }
        return .make(db, driverId: id)
    }
}
