//
//  TeamStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/TeamStrategy.kt
//

import Foundation

struct TeamKpis: Equatable {
    /// 0..4؛ عند ٤ يظهر ✓ بدل «n/٤».
    let arrivalStage: Int
    let newRequests: Int
    let sentUpdates: Int

    var arrivalCompleted: Bool { arrivalStage >= arrivalSteps }
}

struct ArchiveSummary: Equatable {
    let guest: String
    let host: String
    let start: MrasemDate
    let end: MrasemDate
    let officialCount: Int
}

/// لوحة فريق المراسم: المؤشرات، الطلبات، التنبيه العام، الأرشيف.
nonisolated final class TeamStrategy {
    private let repository: MissionRepository

    init(repository: MissionRepository) {
        self.repository = repository
    }

    func kpis(state: MrasemState? = nil) -> TeamKpis {
        let state = state ?? repository.state
        return TeamKpis(
            arrivalStage: state.arrived(),
            newRequests: state.requests(for: state.mode).count { $0.status == .new },
            sentUpdates: state.notices(for: state.mode).count
        )
    }

    func requests(state: MrasemState? = nil) -> [GuestRequest] {
        let state = state ?? repository.state
        return state.requests(for: state.mode)
    }

    /// «تم الترتيب»: الطلب يبقى done + Notice للضيف. يرجّع false لو الطلب مش موجود أو منجز.
    func resolveRequest(_ id: Int64) -> Bool {
        let state = repository.state
        guard let request = state.requests.first(where: { $0.id == id }) else { return false }
        guard request.status != .done else { return false }

        repository.setRequestStatus(id: id, status: .done)
        repository.addNotice(mode: request.mode, content: .requestResolved(place: request.place))
        return true
    }

    /// «إرسال تنبيه عام للوفد». النص الفاضي يتجاهل.
    func broadcast(_ text: String) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }

        let state = repository.state
        repository.addNotice(mode: state.mode, content: .broadcast(value))
        return true
    }

    func archive(state: MrasemState? = nil) -> ArchiveSummary {
        let state = state ?? repository.state
        let mission = state.mission
        return ArchiveSummary(
            guest: mission.guest,
            host: mission.host,
            start: mission.start,
            end: mission.end,
            officialCount: mission.officialCount
        )
    }
}
