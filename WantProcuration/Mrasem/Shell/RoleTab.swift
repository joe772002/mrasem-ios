//
//  RoleTab.swift
//  Mrasem
//
//  Phase 13 — تابات كل دور. الضيف والفريق عندهم شاشاتهم (Phases 4–7)، والباقي «قريباً» لحد ما تتبني
//  شاشاتهم في Phases 14–16 (الأدمن 14/15، السائق والمرافق 16).
//

import Foundation

/// تاب لسه شاشته ما اتبنتش.
enum SoonTab: CaseIterable, Hashable {
    case adminResources
    case adminPlaces
    case adminRequests
    case driverTrips
    case driverSchedule
    case escortDelegation
    case escortNotices

    var labelKey: String {
        switch self {
        case .adminResources: return "mrasem_tab_admin_resources"
        case .adminPlaces: return "mrasem_tab_admin_places"
        case .adminRequests: return "mrasem_tab_admin_requests"
        case .driverTrips: return "mrasem_tab_driver_trips"
        case .driverSchedule: return "mrasem_tab_driver_schedule"
        case .escortDelegation: return "mrasem_tab_escort_delegation"
        case .escortNotices: return "mrasem_tab_notices"
        }
    }

    /// المرحلة اللي هتتبني فيها الشاشة (Phase 14/15/16).
    var phase: Int {
        switch self {
        case .adminResources, .adminPlaces, .adminRequests: return 15
        case .driverTrips, .driverSchedule, .escortDelegation, .escortNotices: return 16
        }
    }
}

@MainActor
extension SoonTab {
    var icon: MrasemIcon {
        switch self {
        case .driverTrips, .escortDelegation: return MrasemIcons.mission
        case .adminResources: return MrasemIcons.services
        case .adminPlaces: return MrasemIcons.explore
        case .adminRequests, .escortNotices: return MrasemIcons.inbox
        case .driverSchedule: return MrasemIcons.plan
        }
    }
}

/// تابات الأدمن اللي شاشاتها اتبنت (Phase 14). الباقي «قريباً» لحد Phase 15.
enum AdminTab: CaseIterable, Hashable {
    case home
    case delegations

    var labelKey: String {
        switch self {
        case .home: return "mrasem_tab_admin_home"
        case .delegations: return "mrasem_tab_admin_delegations"
        }
    }
}

@MainActor
extension AdminTab {
    var icon: MrasemIcon {
        switch self {
        case .home: return MrasemIcons.dash
        case .delegations: return MrasemIcons.mission
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
            return [.admin(.home), .admin(.delegations), .soon(.adminResources), .soon(.adminPlaces), .soon(.adminRequests)]
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
