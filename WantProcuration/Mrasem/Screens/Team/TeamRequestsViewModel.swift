//
//  TeamRequestsViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamRequestsViewModel.kt
//

import Foundation
import Combine

struct TeamRequestsUiState: Equatable {
    let header: TeamHeaderUi
    /// طلبات الوضع الحالي بترتيب وصولها.
    let requests: [GuestRequest]

    static func make(_ state: MrasemState, team: TeamStrategy) -> TeamRequestsUiState {
        TeamRequestsUiState(header: .make(state, team: team), requests: team.requests(state: state))
    }
}

/// تاب «الطلبات» للفريق (01-DESIGN-SPEC §8).
final class TeamRequestsViewModel: ObservableObject {
    @Published private(set) var uiState: TeamRequestsUiState

    private let session: MrasemSessionStrategy
    private let team: TeamStrategy
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, team: TeamStrategy, toastBus: MrasemToastBus) {
        self.session = session
        self.team = team
        self.toastBus = toastBus
        self.uiState = TeamRequestsUiState.make(session.state, team: team)

        session.statePublisher
            .map { TeamRequestsUiState.make($0, team: team) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    func onSection(_ tab: TeamTab) {
        session.selectTeamTab(tab)
    }

    /// «تم الترتيب».
    func onResolve(_ id: Int64) {
        guard team.resolveRequest(id) else { return }
        toastBus.show(ToastMessage(
            .res("mrasem_team_toast_resolved_strong"),
            .res("mrasem_team_toast_resolved_rest")
        ))
    }
}
