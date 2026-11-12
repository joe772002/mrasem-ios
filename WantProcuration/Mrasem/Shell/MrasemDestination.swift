//
//  MrasemDestination.swift
//  Mrasem
//
//  Mirrors Android: ui/screens/shell/MrasemDestination.kt
//

import Foundation

/// الوجهات العشرة داخل الـ Shell (٦ للضيف + ٤ للفريق).
nonisolated enum MrasemDestination: CaseIterable, Hashable {
    case mission
    case plan
    case services
    case explore
    case `protocol`
    case assistant
    case teamVisit
    case teamChanges
    case teamRequests
    case teamArchive

    /// مفتاح اسم التاب في `Localizable.xcstrings`.
    var labelKey: String {
        switch self {
        case .mission: return "mrasem_tab_mission"
        case .plan: return "mrasem_tab_plan"
        case .services: return "mrasem_tab_services"
        case .explore: return "mrasem_tab_explore"
        case .`protocol`: return "mrasem_tab_protocol"
        case .assistant: return "mrasem_tab_assistant"
        case .teamVisit: return "mrasem_tab_team_visit"
        case .teamChanges: return "mrasem_tab_team_changes"
        case .teamRequests: return "mrasem_tab_team_requests"
        case .teamArchive: return "mrasem_tab_team_archive"
        }
    }

    static let guest: [MrasemDestination] = [.mission, .plan, .services, .explore, .`protocol`, .assistant]
    static let team: [MrasemDestination] = [.teamVisit, .teamChanges, .teamRequests, .teamArchive]

    static func of(_ tab: GuestTab) -> MrasemDestination {
        guest[GuestTab.allCases.firstIndex(of: tab)!]
    }

    static func of(_ tab: TeamTab) -> MrasemDestination {
        team[TeamTab.allCases.firstIndex(of: tab)!]
    }

    static func current(role: UserRole, guestTab: GuestTab, teamTab: TeamTab) -> MrasemDestination {
        role == .guest ? of(guestTab) : of(teamTab)
    }

    static func tabs(for role: UserRole) -> [MrasemDestination] {
        role == .guest ? guest : team
    }

    var guestTab: GuestTab? {
        MrasemDestination.guest.firstIndex(of: self).map { GuestTab.allCases[$0] }
    }

    var teamTab: TeamTab? {
        MrasemDestination.team.firstIndex(of: self).map { TeamTab.allCases[$0] }
    }
}

@MainActor
extension MrasemDestination {
    var icon: MrasemIcon {
        switch self {
        case .mission: return MrasemIcons.mission
        case .plan: return MrasemIcons.plan
        case .services: return MrasemIcons.services
        case .explore: return MrasemIcons.explore
        case .`protocol`: return MrasemIcons.`protocol`
        case .assistant: return MrasemIcons.assistant
        case .teamVisit: return MrasemIcons.edit
        case .teamChanges: return MrasemIcons.plan
        case .teamRequests: return MrasemIcons.inbox
        case .teamArchive: return MrasemIcons.dash
        }
    }
}
