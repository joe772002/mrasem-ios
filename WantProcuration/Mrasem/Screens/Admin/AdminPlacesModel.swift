//
//  AdminPlacesModel.swift
//  Mrasem
//
//  Phase 15 — تاب «الأماكن»: الفلتر والإضافة والتعديل والحذف عبر `ResourceService`.
//

import Foundation
import Combine

final class AdminPlacesModel: ObservableObject {
    @Published private(set) var uiState: AdminPlacesState

    private let backend: MrasemBackend
    private let toastBus: MrasemToastBus
    private var filter: PlaceFilter = .all
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend, toastBus: MrasemToastBus) {
        self.backend = backend
        self.toastBus = toastBus
        uiState = .make(backend.database, filter: .all)

        backend.store.publisher
            .sink { [weak self] db in
                guard let self else { return }
                let next = AdminPlacesState.make(db, filter: self.filter)
                if next != self.uiState { self.uiState = next }
            }
            .store(in: &cancellables)
    }

    func onFilter(_ value: PlaceFilter) {
        filter = value
        uiState = .make(backend.database, filter: value)
    }

    func newDraft() -> PlaceDraft {
        var draft = PlaceDraft()
        if let kind = filter.kind { draft.kind = kind }
        return draft
    }

    func draft(place id: String) -> PlaceDraft? {
        backend.database.place(id).map { PlaceDraft($0) }
    }

    func save(_ draft: PlaceDraft) -> String? {
        switch backend.resources.savePlace(draft.record()) {
        case let .failure(error):
            return error.messageKey
        case .success:
            toastBus.show(ToastMessage(.res("mrasem_admin_toast_saved_strong"), .res("mrasem_admin_toast_saved_rest")))
            return nil
        }
    }

    func delete(_ id: String) {
        backend.resources.deletePlace(id)
    }
}
