//
//  NoticesModel.swift
//  Mrasem
//
//  Phase 16 — صندوق تنبيهات المستخدم الحالي (تاب المرافق وبطاقة في شاشة السائق).
//

import Foundation
import Combine

final class NoticesModel: ObservableObject {
    @Published private(set) var uiState: NoticeInboxState

    private let backend: MrasemBackend
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend) {
        self.backend = backend
        uiState = .make(backend.database, user: backend.database.currentUser)

        backend.store.publisher
            .map { NoticeInboxState.make($0, user: $0.currentUser) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    func markAllRead() {
        backend.markNoticesRead()
    }
}
