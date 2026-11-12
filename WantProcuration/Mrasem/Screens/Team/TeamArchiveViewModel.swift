//
//  TeamArchiveViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamArchiveViewModel.kt
//

import Foundation
import Combine

struct TeamArchiveUiState: Equatable {
    let header: TeamHeaderUi
    let archive: ArchiveSummary

    static func make(_ state: MrasemState, team: TeamStrategy) -> TeamArchiveUiState {
        TeamArchiveUiState(header: .make(state, team: team), archive: team.archive(state: state))
    }
}

/// تاب «الأرشيف» للفريق (01-DESIGN-SPEC §8).
final class TeamArchiveViewModel: ObservableObject {
    @Published private(set) var uiState: TeamArchiveUiState

    private let session: MrasemSessionStrategy
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, team: TeamStrategy, toastBus: MrasemToastBus) {
        self.session = session
        self.toastBus = toastBus
        self.uiState = TeamArchiveUiState.make(session.state, team: team)

        session.statePublisher
            .map { TeamArchiveUiState.make($0, team: team) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    func onSection(_ tab: TeamTab) {
        session.selectTeamTab(tab)
    }

    /// «إنشاء تقرير الزيارة»: توست بس في النموذج الأولي.
    func onReport() {
        toastBus.show(ToastMessage(
            .res("mrasem_team_toast_report_strong"),
            .res("mrasem_team_toast_report_rest")
        ))
    }
}
