//
//  MrasemAppFlow.swift
//  Mrasem
//
//  Phase 13 — مرحلة التطبيق: سؤال البداية (أول مرة) ← «اختر المستخدم» (كل تشغيل، وعند الطلب) ← الـ Shell.
//

import Foundation
import Combine

nonisolated final class MrasemAppFlow: ObservableObject {
    enum Stage: Equatable {
        case chooseStart
        case pickUser
        case main
    }

    @Published private(set) var stage: Stage

    private let backend: MrasemBackend
    /// المستخدم أكّد اختياره في التشغيل ده.
    private var confirmed: Bool
    private var cancellables = Set<AnyCancellable>()

    /// `confirmed: true` للـ Previews عشان تفتح على الـ Shell مباشرة.
    init(backend: MrasemBackend, confirmed: Bool = false) {
        self.backend = backend
        self.confirmed = confirmed
        self.stage = Self.stage(backend.database, confirmed: confirmed)

        backend.store.publisher
            .sink { [weak self] database in self?.refresh(database) }
            .store(in: &cancellables)
    }

    func startChosen(demo: Bool) {
        confirmed = false
        backend.chooseStart(demo: demo)
    }

    func userChosen(_ user: UserRef) {
        confirmed = true
        backend.switchUser(to: user)
        refresh(backend.database)
    }

    /// زر التبديل في الهيدر.
    func openPicker() {
        confirmed = false
        refresh(backend.database)
    }

    /// «رجوع» من الاختيار لنفس المستخدم.
    func keepCurrentUser() {
        guard backend.database.currentUser != nil else { return }
        confirmed = true
        refresh(backend.database)
    }

    private func refresh(_ database: MrasemDatabase) {
        let next = Self.stage(database, confirmed: confirmed)
        if next != stage { stage = next }
    }

    static func stage(_ database: MrasemDatabase, confirmed: Bool) -> Stage {
        if !database.didChooseStart { return .chooseStart }
        if database.currentUser == nil || !confirmed { return .pickUser }
        return .main
    }
}
