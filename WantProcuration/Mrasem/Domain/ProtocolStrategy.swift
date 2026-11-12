//
//  ProtocolStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/ProtocolStrategy.kt
//

import Foundation

struct ChecklistItem: Equatable {
    let index: Int
    let label: String
    let checked: Bool
}

struct ProtocolContent: Equatable {
    let nextMeeting: NextMeeting
    let dressCode: DressCode
    let dress: DressSet
    let checklist: [ChecklistItem]
    let readyCount: Int
    let customs: [String]
    /// عنوان الأعراف: «آداب وأعراف في قطر» (inbound) / «أعراف بلد الوجهة» (outbound).
    let isInbound: Bool
    let guides: [String]
}

nonisolated final class ProtocolStrategy {
    private let repository: MissionRepository

    init(repository: MissionRepository) {
        self.repository = repository
    }

    func content(state: MrasemState? = nil) -> ProtocolContent {
        let state = state ?? repository.state
        let checked = state.checks(for: state.mode)

        let checklist = state.reference.checklist.enumerated().map { index, label in
            ChecklistItem(index: index, label: label, checked: checked.contains(index))
        }

        return ProtocolContent(
            nextMeeting: state.mission.nextMeeting,
            dressCode: state.dress,
            dress: state.reference.dressSet(state.dress),
            checklist: checklist,
            readyCount: checklist.count { $0.checked },
            customs: state.mission.customs,
            isInbound: state.mode == .inbound,
            guides: state.reference.guides
        )
    }

    /// يقلب عنصر في «قبل الخروج من الفندق» — محفوظ لكل وضع.
    func toggleCheck(_ index: Int) {
        let state = repository.state
        guard state.reference.checklist.indices.contains(index) else { return }
        let checked = state.checks(for: state.mode)
        repository.setCheck(mode: state.mode, index: index, checked: !checked.contains(index))
    }
}
