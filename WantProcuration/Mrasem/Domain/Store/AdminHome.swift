//
//  AdminHome.swift
//  Mrasem
//
//  Phase 14 — لوحة تحكم الأدمن (البوابة: «الرئيسية»): مؤشرات، تحركات اليوم، وبنود «تحتاج إجراء».
//  دوال صافية فوق `PortalInsights` عشان تتختبر من غير UI.
//

import Foundation

struct AdminMovement: Equatable, Identifiable {
    let id: String
    let time: String
    let title: String
    let delegationName: String
    let driverName: String?
    let hasConflict: Bool
}

/// بند «تحتاج إجراء».
struct AdminActionItem: Equatable, Identifiable {
    enum Kind: String, Equatable {
        /// تعارض سائقين (مفيش وفد واحد معيّن).
        case conflicts
        /// طلبات جديدة من الضيوف.
        case requests
        /// نواقص في وفد (سيارة / غرفة / مرافق / فندق).
        case gaps
    }

    let kind: Kind
    let delegationId: String?
    let delegationName: String
    let count: Int

    var id: String { kind.rawValue + "|" + (delegationId ?? "") }
}

struct AdminHomeState: Equatable {
    let summary: DashboardSummary
    let today: String
    let movements: [AdminMovement]
    let actions: [AdminActionItem]
    /// مفيش وفود خالص (التطبيق فاضي) ← الشاشة بتوضّح إزاي تبدأ.
    let isEmpty: Bool
}

nonisolated enum AdminHomeBuilder {

    static func make(_ db: MrasemDatabase, today: String) -> AdminHomeState {
        let conflictIds = PortalInsights.conflictItemIds(db)

        let movements = PortalInsights.movements(db, on: today).map { item in
            AdminMovement(
                id: item.id,
                time: item.time,
                title: item.title,
                delegationName: db.delegation(item.delegationId)?.name ?? "",
                driverName: PortalInsights.driver(of: item, in: db)?.name,
                hasConflict: conflictIds.contains(item.id)
            )
        }

        return AdminHomeState(
            summary: PortalInsights.dashboard(db),
            today: today,
            movements: movements,
            actions: actions(db),
            isEmpty: db.delegations.isEmpty
        )
    }

    /// تعارضات، طلبات جديدة، ثم الوفود الأكتر نواقص.
    static func actions(_ db: MrasemDatabase) -> [AdminActionItem] {
        var out: [AdminActionItem] = []

        let conflicts = PortalInsights.conflicts(db).count
        if conflicts > 0 {
            out.append(AdminActionItem(kind: .conflicts, delegationId: nil, delegationName: "", count: conflicts))
        }

        let requests = PortalInsights.newRequests(db).count
        if requests > 0 {
            out.append(AdminActionItem(kind: .requests, delegationId: nil, delegationName: "", count: requests))
        }

        let gaps = PortalInsights.activeDelegations(db)
            .map { ($0, PortalInsights.gaps(db, delegationId: $0.id).missingCount) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.start < $1.0.start }
        out += gaps.map {
            AdminActionItem(kind: .gaps, delegationId: $0.0.id, delegationName: $0.0.name, count: $0.1)
        }
        return out
    }
}
