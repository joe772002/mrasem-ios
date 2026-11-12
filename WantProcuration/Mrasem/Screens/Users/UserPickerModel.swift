//
//  UserPickerModel.swift
//  Mrasem
//
//  Phase 13 — حالة شاشة «اختر المستخدم»: الأقسام والتنبيهات غير المقروءة، بتتحدث مع أي تغيير في القاعدة.
//

import Foundation
import Combine

struct UserPickerState: Equatable {
    let sections: [UserSection]
    /// فيه مستخدم حالي نرجع له.
    let canGoBack: Bool
    /// الأدمن لوحده (قاعدة فاضية): بنوضح إزاي يضيف الباقي.
    let onlyOneUser: Bool

    static func make(_ db: MrasemDatabase) -> UserPickerState {
        let sections = UserDirectory.sections(db)
        return UserPickerState(
            sections: sections,
            canGoBack: db.currentUser != nil,
            onlyOneUser: sections.reduce(0) { $0 + $1.entries.count } <= 1
        )
    }
}

final class UserPickerModel: ObservableObject {
    @Published private(set) var uiState: UserPickerState

    private let flow: MrasemAppFlow
    private var cancellables = Set<AnyCancellable>()

    init(context: MrasemAppContext) {
        self.flow = context.flow
        self.uiState = UserPickerState.make(context.backend.database)

        context.backend.store.publisher
            .map(UserPickerState.make)
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    func onSelect(_ entry: UserEntry) {
        flow.userChosen(entry.ref)
    }

    func onBack() {
        flow.keepCurrentUser()
    }
}
