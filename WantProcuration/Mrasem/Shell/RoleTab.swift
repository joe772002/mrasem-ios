//
//  RoleTab.swift
//  Mrasem
//
//  Phase 13 — تابات كل دور. الضيف والفريق عندهم شاشاتهم (Phases 4–7) والأدمن (14–15)، والباقي «قريباً» لحد Phase 16.
//

import Foundation

/// تاب لسه شاشته ما اتبنتش.
enum SoonTab: CaseIterable, Hashable {
    case driverTrips
    case driverSchedule
    case escortDelegation
    case escortNotices

    var labelKey: String {
        switch self {
        case .driverTrips: return "mrasem_tab_driver_trips"
        case .driverSchedule: return "mrasem_tab_driver_schedule"
        case .escortDelegation: return "mrasem_tab_escort_delegation"
        case .escortNotices: return "mrasem_tab_notices"
        }
    }

    /// المرحلة اللي هتتبني فيها الشاشة (Phase 14/15/16).
    var phase: Int {
        switch self {
        case .driverTrips, .driverSchedule, .escortDelegation, .escortNotices: return 16
        }
    }
}

@MainActor
extension SoonTab {
    var icon: MrasemIcon {
        switch self {
        case .driverTrips, .escortDelegation: return MrasemIcons.mission
        case .escortNotices: return MrasemIcons.inbox
        case .driverSchedule: return MrasemIcons.plan
        }
    }
}

/// تابات الأدمن (Phase 14–15). الإعدادات من زر الهيدر.
enum AdminTab: CaseIterable, Hashable {
    case home
    case delegations
    case resources
    case places
    case requests

    var labelKey: String {
        switch self {
        case .home: return "mrasem_tab_admin_home"
        case .delegations: return "mrasem_tab_admin_delegations"
        case .resources: return "mrasem_tab_admin_resources"
        case .places: return "mrasem_tab_admin_places"
        case .requests: return "mrasem_tab_admin_requests"
        }
    }
}

@MainActor
extension AdminTab {
    var icon: MrasemIcon {
        switch self {
        case .home: return MrasemIcons.dash
        case .delegations: return MrasemIcons.mission
        case .resources: return MrasemIcons.services
        case .places: return MrasemIcons.explore
        case .requests: return MrasemIcons.inbox
        }
    }
}

enum RoleTab: Hashable {
    case screen(MrasemDestination)
    case admin(AdminTab)
    case soon(SoonTab)

    var labelKey: String {
        switch self {
        case let .screen(destination): return destination.labelKey
        case let .admin(tab): return tab.labelKey
        case let .soon(tab): return tab.labelKey
        }
    }

    static func tabs(for role: ShellRole) -> [RoleTab] {
        switch role {
        case .admin:
            return AdminTab.allCases.map { .admin($0) }
        case .coordinator:
            return MrasemDestination.team.map { .screen($0) }
        case .member:
            return MrasemDestination.guest.map { .screen($0) }
        case .escort:
            return [.soon(.escortDelegation), .soon(.escortNotices)]
        case .driver:
            return [.soon(.driverTrips), .soon(.driverSchedule)]
        }
    }
}

@MainActor
extension RoleTab {
    var icon: MrasemIcon {
        switch self {
        case let .screen(destination): return destination.icon
        case let .admin(tab): return tab.icon
        case let .soon(tab): return tab.icon
        }
    }
}
