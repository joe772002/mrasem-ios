//
//  TeamPreviewData.swift
//  Mrasem
//
//  بيانات المعاينة لشاشات الفريق (من MrasemDemoData، من غير نصوص حرفية).
//

import Foundation

enum TeamPreviewData {
    static func visit() -> TeamVisitUiState {
        let mission = MrasemDemoData.inbound
        return TeamVisitUiState(
            header: TeamHeaderUi(kpis: TeamKpis(arrivalStage: 2, newRequests: 1, sentUpdates: 3), tab: .visit),
            guest: mission.guest,
            form: VisitForm(data: VisitUpdateStrategy.visitData(mission), dress: .formal)
        )
    }

    static func changes() -> TeamChangesUiState {
        let ref = ProgramStrategy.keyItem(MrasemDemoData.inbound)
        return TeamChangesUiState(
            header: TeamHeaderUi(kpis: TeamKpis(arrivalStage: 4, newRequests: 0, sentUpdates: 1), tab: .changes),
            keyItem: ref.map { KeyItemUi(title: $0.item.title, dayLabel: $0.dayLabel, time: $0.item.time) }
        )
    }

    static func requests(empty: Bool = false) -> TeamRequestsUiState {
        let mission = MrasemDemoData.inbound
        let list: [GuestRequest] = empty ? [] : [
            GuestRequest(id: 1, mode: .inbound, kind: .visit, place: mission.places[0].name, text: nil, status: .new),
            GuestRequest(id: 2, mode: .inbound, kind: .question, place: nil, text: MrasemDemoData.quickQuestions[0], status: .new),
            GuestRequest(id: 3, mode: .inbound, kind: .visit, place: mission.places[1].name, text: nil, status: .done),
        ]
        return TeamRequestsUiState(
            header: TeamHeaderUi(kpis: TeamKpis(arrivalStage: 1, newRequests: empty ? 0 : 2, sentUpdates: 1), tab: .requests),
            requests: list
        )
    }

    static func archive() -> TeamArchiveUiState {
        let m = MrasemDemoData.outbound
        return TeamArchiveUiState(
            header: TeamHeaderUi(kpis: TeamKpis(arrivalStage: 4, newRequests: 0, sentUpdates: 2), tab: .archive),
            archive: ArchiveSummary(guest: m.guest, host: m.host, start: m.start, end: m.end, officialCount: m.officialCount)
        )
    }
}
