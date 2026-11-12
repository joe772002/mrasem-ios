//
//  AdminDelegationList.swift
//  Mrasem
//
//  Phase 14 — قائمة الوفود للأدمن (البوابة: «الوفود والبرامج»): فلاتر وصف لكل وفد.
//

import Foundation

enum DelegationFilter: String, CaseIterable, Hashable {
    case all
    case active
    case draft
    case archived

    var titleKey: String { "mrasem_admin_filter_" + rawValue }

    func includes(_ status: DelegationStatus) -> Bool {
        switch self {
        case .all: return true
        case .active: return status == .active
        case .draft: return status == .draft
        case .archived: return status == .archived
        }
    }
}

extension DelegationStatus {
    var labelKey: String { "mrasem_admin_status_" + rawValue }
}

struct DelegationRow: Equatable, Identifiable {
    let id: String
    let name: String
    let mode: MissionMode
    let start: String
    let end: String
    let status: DelegationStatus
    let memberCount: Int
    let readiness: Int
    let missing: Int
    let hotelName: String?
}

nonisolated enum AdminDelegationList {

    /// الأقرب بداية أولاً، وبعدها بالاسم.
    static func rows(_ db: MrasemDatabase, filter: DelegationFilter) -> [DelegationRow] {
        db.delegations
            .filter { filter.includes($0.status) }
            .sorted { ($0.start, $0.name) < ($1.start, $1.name) }
            .map { delegation in
                DelegationRow(
                    id: delegation.id,
                    name: delegation.name,
                    mode: delegation.mode,
                    start: delegation.start,
                    end: delegation.end,
                    status: delegation.status,
                    memberCount: db.members.count { $0.delegationId == delegation.id },
                    readiness: PortalInsights.readiness(db, delegationId: delegation.id),
                    missing: PortalInsights.gaps(db, delegationId: delegation.id).missingCount,
                    hotelName: db.place(delegation.hotelId)?.name
                )
            }
    }

    static func counts(_ db: MrasemDatabase) -> [DelegationFilter: Int] {
        Dictionary(uniqueKeysWithValues: DelegationFilter.allCases.map { filter in
            (filter, db.delegations.count { filter.includes($0.status) })
        })
    }
}
