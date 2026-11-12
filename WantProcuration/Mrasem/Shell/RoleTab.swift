//
//  RoleTab.swift
//  Mrasem
//
//  Phase 13/16 — تابات كل دور: الضيف والفريق (Phases 4–7)، الأدمن (14–15)، السائق والمرافق (16).
//

import Foundation

/// تابات السائق (Phase 16).
enum DriverTab: CaseIterable, Hashable {
    case trips
    case schedule

    var labelKey: String {
        switch self {
        case .trips: return "mrasem_tab_driver_trips"
        case .schedule: return "mrasem_tab_driver_schedule"
        }
    }
}

/// تابات المرافق (Phase 16).
enum EscortTab: CaseIterable, Hashable {
    case delegation
    case notices

    var labelKey: String {
        switch self {
        case .delegation: return "mrasem_tab_escort_delegation"
        case .notices: return "mrasem_tab_notices"
        }
    }
}

@MainActor
extension DriverTab {
    var icon: MrasemIcon {
        switch self {
        case .trips: return MrasemIcons.mission
        case .schedule: return MrasemIcons.plan
        }
    }
}

@MainActor
extension EscortTab {
    var icon: MrasemIcon {
        switch self {
        case .delegation: return MrasemIcons.mission
        case .notices: return MrasemIcons.inbox
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
    case driver(DriverTab)
    case escort(EscortTab)

    var labelKey: String {
        switch self {
        case let .screen(destination): return destination.labelKey
        case let .admin(tab): return tab.labelKey
        case let .driver(tab): return tab.labelKey
        case let .escort(tab): return tab.labelKey
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
            return EscortTab.allCases.map { .escort($0) }
        case .driver:
            return DriverTab.allCases.map { .driver($0) }
        }
    }
}

@MainActor
extension RoleTab {
    var icon: MrasemIcon {
        switch self {
        case let .screen(destination): return destination.icon
        case let .admin(tab): return tab.icon
        case let .driver(tab): return tab.icon
        case let .escort(tab): return tab.icon
        }
    }
}
