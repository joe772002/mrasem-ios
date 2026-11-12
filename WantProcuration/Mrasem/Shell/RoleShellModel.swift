//
//  RoleShellModel.swift
//  Mrasem
//
//  Phase 13 — حالة الـ Shell حسب المستخدم الحالي: اسمه ودوره وتنبيهاته غير المقروءة وتاباته ووفوده.
//

import Foundation
import Combine

struct DelegationChoice: Identifiable, Equatable {
    let id: String
    let name: String
}

struct RoleShellState: Equatable {
    let userName: String
    let role: ShellRole
    let unread: Int
    let tabs: [RoleTab]
    let selected: RoleTab
    /// الوفود اللي يقدر يختار منها (منسق / أدمن / مرافق). فاضية لو مفيش.
    let delegations: [DelegationChoice]
    let selectedDelegationId: String?
    /// الشاشات القديمة (ضيف / فريق) محتاجة وفد؛ من غيره بنعرض «مفيش وفد».
    let needsDelegation: Bool
    let hasDelegation: Bool

    var tabIndex: Int { tabs.firstIndex(of: selected) ?? 0 }

    static let empty = RoleShellState(
        userName: "", role: .member, unread: 0, tabs: [], selected: .admin(.home),
        delegations: [], selectedDelegationId: nil, needsDelegation: false, hasDelegation: false
    )

    static func make(_ db: MrasemDatabase, nav: RepoNav, chosen: RoleTab?) -> RoleShellState {
        guard let user = db.currentUser, db.exists(user) else { return .empty }

        let role = ShellRole.of(user, in: db)
        let tabs = RoleTab.tabs(for: role)
        let scope = ViewScope.resolve(db, selected: nav.selectedDelegationId)
        let choices = ViewScope.delegations(for: user, in: db).map { DelegationChoice(id: $0.id, name: $0.name) }

        let selected: RoleTab
        switch role {
        case .member: selected = .screen(MrasemDestination.of(nav.guestTab))
        case .coordinator: selected = .screen(MrasemDestination.of(nav.teamTab))
        case .admin, .escort, .driver:
            selected = chosen.flatMap { tabs.contains($0) ? $0 : nil } ?? tabs.first ?? .admin(.home)
        }

        return RoleShellState(
            userName: UserDirectory.name(of: user, in: db) ?? "",
            role: role,
            unread: db.unreadCount(for: user),
            tabs: tabs,
            selected: selected,
            delegations: role == .member || role == .admin ? [] : choices,
            selectedDelegationId: scope.delegationId,
            needsDelegation: role == .member || role == .coordinator,
            hasDelegation: scope.delegationId != nil
        )
    }
}

final class RoleShellModel: ObservableObject {
    @Published private(set) var uiState: RoleShellState = .empty

    private let backend: MrasemBackend
    private let session: MrasemSessionStrategy
    private var chosen: RoleTab?
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend, session: MrasemSessionStrategy) {
        self.backend = backend
        self.session = session

        // يرجّع آخر تاب ضيف اتحفظ قبل ما نبدأ نسمع للتغييرات (زي Android).
        session.restoreGuestTab()

        Publishers.CombineLatest(backend.store.publisher, backend.repository.navPublisher)
            .sink { [weak self] database, nav in self?.rebuild(database, nav) }
            .store(in: &cancellables)

        backend.repository.navPublisher
            .map(\.guestTab)
            .removeDuplicates()
            .dropFirst()
            .sink { [session] tab in session.persistGuestTab(tab) }
            .store(in: &cancellables)
    }

    func select(_ tab: RoleTab) {
        switch tab {
        case let .screen(destination):
            if let guest = destination.guestTab {
                session.selectGuestTab(guest)
            } else if let team = destination.teamTab {
                session.selectTeamTab(team)
            }
        case .admin, .driver, .escort:
            chosen = tab
            rebuild(backend.database, backend.repository.nav)
        }
    }

    func select(delegation id: String) {
        backend.repository.selectDelegation(id)
    }

    private func rebuild(_ database: MrasemDatabase, _ nav: RepoNav) {
        let next = RoleShellState.make(database, nav: nav, chosen: chosen)
        if next != uiState { uiState = next }
    }
}
