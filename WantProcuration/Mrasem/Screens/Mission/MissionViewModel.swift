//
//  MissionViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/mission/MissionViewModel.kt
//

import Foundation
import Combine

struct MissionUiState: Equatable {
    let notices: [Notice]
    let mission: Mission
    let summary: MissionSummary

    static func make(_ state: MrasemState, summary: MissionSummaryStrategy) -> MissionUiState {
        MissionUiState(
            notices: state.recentNotices(),
            mission: state.mission,
            summary: summary.summary(state: state)
        )
    }
}

/// حالة شاشة المهمة (الضيف). كل الأرقام والحالات من الـ strategies؛ الـ UI بيعرض بس.
final class MissionViewModel: ObservableObject {
    @Published private(set) var uiState: MissionUiState

    private let summaryStrategy: MissionSummaryStrategy
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, summary: MissionSummaryStrategy, toastBus: MrasemToastBus) {
        self.summaryStrategy = summary
        self.toastBus = toastBus
        self.uiState = MissionUiState.make(session.state, summary: summary)

        session.statePublisher
            .map { MissionUiState.make($0, summary: summary) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    /// زر حالة الوصول: يقدّم خطوة ويعرض توست الخطوة.
    func onArrivalClick() {
        let receiverName = uiState.mission.receiver.name
        guard let stage = summaryStrategy.advanceArrival() else { return }
        toastBus.show(Self.arrivalToast(stage: stage, receiverName: receiverName))
    }

    static func arrivalToast(stage: Int, receiverName: String) -> ToastMessage {
        switch stage {
        case 1:
            return ToastMessage(
                .res("mrasem_toast_arrival_1_strong"),
                .res("mrasem_toast_arrival_1_rest", [receiverName])
            )
        case 2:
            return ToastMessage(.res("mrasem_toast_arrival_2_strong"), .res("mrasem_toast_arrival_2_rest"))
        case 3:
            return ToastMessage(.res("mrasem_toast_arrival_3_strong"), .res("mrasem_toast_arrival_3_rest"))
        default:
            return ToastMessage(.res("mrasem_toast_arrival_4_strong"), .res("mrasem_toast_arrival_4_rest"))
        }
    }
}
