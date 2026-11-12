//
//  TeamVisitViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamVisitViewModel.kt
//

import Foundation
import Combine

struct TeamVisitUiState: Equatable {
    let header: TeamHeaderUi
    let guest: String
    /// القيم الحالية في الـ source اللي بيقرأ منه الضيف — النموذج بيبدأ منها.
    let form: VisitForm

    static func make(_ state: MrasemState, team: TeamStrategy, visit: VisitUpdateStrategy) -> TeamVisitUiState {
        TeamVisitUiState(
            header: .make(state, team: team),
            guest: state.mission.guest,
            form: visit.currentForm(state: state)
        )
    }
}

/// تاب «الزيارة» للفريق (01-DESIGN-SPEC §8).
final class TeamVisitViewModel: ObservableObject {
    @Published private(set) var uiState: TeamVisitUiState

    private let session: MrasemSessionStrategy
    private let visit: VisitUpdateStrategy
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, team: TeamStrategy, visit: VisitUpdateStrategy, toastBus: MrasemToastBus) {
        self.session = session
        self.visit = visit
        self.toastBus = toastBus
        self.uiState = TeamVisitUiState.make(session.state, team: team, visit: visit)

        session.statePublisher
            .map { TeamVisitUiState.make($0, team: team, visit: visit) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    func onSection(_ tab: TeamTab) {
        session.selectTeamTab(tab)
    }

    /// «حفظ وإشعار الضيف».
    func onSave(_ form: VisitForm) {
        switch visit.save(form) {
        case .noChanges:
            toastBus.show(ToastMessage(.raw(""), .res("mrasem_team_toast_no_changes")))
        case .saved:
            toastBus.show(ToastMessage(
                .res("mrasem_team_toast_saved_strong"),
                .res("mrasem_team_toast_saved_rest")
            ))
        }
    }
}
