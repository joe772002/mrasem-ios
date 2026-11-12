//
//  AdminHomeModel.swift
//  Mrasem
//
//  Phase 14 — حالة «الرئيسية» للأدمن: بتتحدّث لحظياً مع أي تعديل في القاعدة.
//

import Foundation
import Combine

final class AdminHomeModel: ObservableObject {
    @Published private(set) var uiState: AdminHomeState

    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend) {
        let today = backend.today
        uiState = AdminHomeBuilder.make(backend.database, today: today().iso)

        backend.store.publisher
            .map { AdminHomeBuilder.make($0, today: today().iso) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }
}
