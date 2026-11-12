//
//  PlanViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/plan/PlanViewModel.kt
//

import Foundation
import Combine

struct PlanUiState: Equatable {
    let notices: [Notice]
    let timeZone: String
    let dayLabels: [String]
    let timeline: DayTimeline

    static func make(_ state: MrasemState, program: ProgramStrategy) -> PlanUiState {
        PlanUiState(
            notices: state.recentNotices(),
            timeZone: state.mission.timeZone,
            dayLabels: state.mission.days.map(\.label),
            timeline: program.timeline(state: state)
        )
    }
}

/// حالة شاشة البرنامج (الضيف).
final class PlanViewModel: ObservableObject {
    @Published private(set) var uiState: PlanUiState

    private let session: MrasemSessionStrategy
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, program: ProgramStrategy) {
        self.session = session
        self.uiState = PlanUiState.make(session.state, program: program)

        session.statePublisher
            .map { PlanUiState.make($0, program: program) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    func onDaySelected(_ index: Int) {
        session.selectDay(index)
    }

    /// chip بطاقة الـ ٣٠ ثانية ← تاب البروتوكول.
    func onKeyCardClick() {
        session.openProtocol()
    }

    /// chip اقتراح الوقت الحر ← تاب استكشف بفلتر «الكل».
    func onFreeTimeSuggestionClick() {
        session.openExploreFromFreeTime()
    }
}
