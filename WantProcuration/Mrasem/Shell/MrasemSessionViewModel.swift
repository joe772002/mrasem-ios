//
//  MrasemSessionViewModel.swift
//  Mrasem
//
//  Mirrors Android: ui/screens/shell/MrasemSessionViewModel.kt
//

import Foundation
import Combine

/// حالة الـ Shell: الوضع، الدور، التاب الحالي. التنبيهات بتجيبها كل شاشة من الـ ViewModel بتاعها.
final class MrasemSessionViewModel: ObservableObject {
    @Published private(set) var uiState: ShellUiState

    private let session: MrasemSessionStrategy
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy) {
        self.session = session
        self.uiState = ShellUiState.from(session.state)

        // يرجّع آخر تاب اتحفظ قبل ما نبدأ نسمع للتغييرات (زي Android: restore ثم drop(1)).
        session.restoreGuestTab()
        uiState = ShellUiState.from(session.state)

        session.statePublisher
            .map(ShellUiState.from)
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)

        // أي تغيير في تاب الضيف (من الـ bottom bar أو من chip) يتحفظ.
        session.statePublisher
            .map(\.guestTab)
            .removeDuplicates()
            .dropFirst()
            .sink { [session] tab in session.persistGuestTab(tab) }
            .store(in: &cancellables)
    }

    func onModeSelected(_ index: Int) {
        session.changeMode(MissionMode.allCases[index])
    }

    func onRoleSelected(_ index: Int) {
        session.changeRole(UserRole.allCases[index])
    }

    func onTabSelected(_ destination: MrasemDestination) {
        if let tab = destination.guestTab {
            session.selectGuestTab(tab)
        } else if let tab = destination.teamTab {
            session.selectTeamTab(tab)
        }
    }
}
