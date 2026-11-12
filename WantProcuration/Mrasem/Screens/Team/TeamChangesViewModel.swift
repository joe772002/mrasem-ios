//
//  TeamChangesViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamChangesViewModel.kt
//

import Foundation
import Combine

/// الفقرة الرئيسية لليوم الثاني كما تظهر في «رادار التغييرات».
struct KeyItemUi: Equatable {
    let title: String
    let dayLabel: String
    let time: String
}

struct TeamChangesUiState: Equatable {
    let header: TeamHeaderUi
    let keyItem: KeyItemUi?

    static func make(_ state: MrasemState, team: TeamStrategy) -> TeamChangesUiState {
        TeamChangesUiState(
            header: .make(state, team: team),
            keyItem: ProgramStrategy.keyItem(state.mission).map {
                KeyItemUi(title: $0.item.title, dayLabel: $0.dayLabel, time: $0.item.time)
            }
        )
    }
}

/// تاب «التغييرات» للفريق (01-DESIGN-SPEC §8).
final class TeamChangesViewModel: ObservableObject {
    @Published private(set) var uiState: TeamChangesUiState

    private let session: MrasemSessionStrategy
    private let team: TeamStrategy
    private let program: ProgramStrategy
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, team: TeamStrategy, program: ProgramStrategy, toastBus: MrasemToastBus) {
        self.session = session
        self.team = team
        self.program = program
        self.toastBus = toastBus
        self.uiState = TeamChangesUiState.make(session.state, team: team)

        session.statePublisher
            .map { TeamChangesUiState.make($0, team: team) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    func onSection(_ tab: TeamTab) {
        session.selectTeamTab(tab)
    }

    /// «تأجيل ٣٠ دقيقة».
    func onPostpone() {
        guard program.postponeKeyItem() != nil else { return }
        toastBus.show(ToastMessage(
            .res("mrasem_team_toast_postponed_strong"),
            .res("mrasem_team_toast_postponed_rest")
        ))
    }

    /// «إرسال تنبيه عام للوفد». يرجّع true لو اتبعت (عشان الحقل يتمسح).
    func onBroadcast(_ text: String) -> Bool {
        guard team.broadcast(text) else { return false }
        toastBus.show(ToastMessage(
            .res("mrasem_team_toast_broadcast_strong"),
            .res("mrasem_team_toast_broadcast_rest")
        ))
        return true
    }
}
