//
//  UserDirectory.swift
//  Mrasem
//
//  Phase 13 — قائمة «اختر المستخدم»: كل شخص في البيانات ممكن «يدخل» بيه، مقسّمين حسب الدور،
//  وجنب كل واحد عدد تنبيهاته غير المقروءة (08 §1).
//

import Foundation

extension UserRef {
    /// مفتاح ثابت للقوائم.
    var key: String {
        switch self {
        case let .team(id): return "team:" + id
        case let .member(id): return "member:" + id
        case let .escort(id): return "escort:" + id
        case let .driver(id): return "driver:" + id
        }
    }
}

enum UserSectionKind: String, CaseIterable, Hashable {
    case team
    case members
    case escorts
    case drivers

    var titleKey: String {
        switch self {
        case .team: return "mrasem_users_section_team"
        case .members: return "mrasem_users_section_members"
        case .escorts: return "mrasem_users_section_escorts"
        case .drivers: return "mrasem_users_section_drivers"
        }
    }
}

/// مفتاح اسم الدور (للـ pill).
extension ShellRole {
    var labelKey: String {
        switch self {
        case .admin: return "mrasem_users_role_admin"
        case .coordinator: return "mrasem_users_role_coordinator"
        case .member: return "mrasem_users_role_member"
        case .escort: return "mrasem_users_role_escort"
        case .driver: return "mrasem_users_role_driver"
        }
    }
}

struct UserEntry: Identifiable, Equatable {
    let ref: UserRef
    let name: String
    let role: ShellRole
    /// سطر تحت الاسم: الصفة أو الوفد أو الهاتف.
    let detail: String
    let unread: Int
    let isCurrent: Bool

    var id: String { ref.key }
}

struct UserSection: Identifiable, Equatable {
    let kind: UserSectionKind
    let entries: [UserEntry]

    var id: String { kind.rawValue }
}

nonisolated enum UserDirectory {

    /// الأقسام اللي فيها مستخدمين بس (G5). أعضاء الوفد النشطين بس (المدعوّ لسه ما دخلش التطبيق).
    static func sections(_ db: MrasemDatabase) -> [UserSection] {
        let team = db.team.map { user in
            entry(.team(user.id), name: user.name, role: user.role == .admin ? .admin : .coordinator,
                  detail: user.phone, db)
        }
        let members = db.members.filter { $0.appStatus == .active }.map { member -> UserEntry in
            let delegation = db.delegation(member.delegationId)?.name ?? ""
            let detail = [member.title, delegation].filter { !$0.isEmpty }.joined(separator: " · ")
            return entry(.member(member.id), name: member.name, role: .member, detail: detail, db)
        }
        let escorts = db.escorts.map { escort in
            entry(.escort(escort.id), name: escort.name, role: .escort, detail: escort.title, db)
        }
        let drivers = db.drivers.map { driver in
            entry(.driver(driver.id), name: driver.name, role: .driver, detail: driver.phone, db)
        }

        return [
            UserSection(kind: .team, entries: team),
            UserSection(kind: .members, entries: members),
            UserSection(kind: .escorts, entries: escorts),
            UserSection(kind: .drivers, entries: drivers),
        ].filter { !$0.entries.isEmpty }
    }

    /// اسم المستخدم، أو `nil` لو مش موجود.
    static func name(of user: UserRef, in db: MrasemDatabase) -> String? {
        switch user {
        case let .team(id): return db.teamUser(id)?.name
        case let .member(id): return db.member(id)?.name
        case let .escort(id): return db.escort(id)?.name
        case let .driver(id): return db.driver(id)?.name
        }
    }

    private static func entry(_ ref: UserRef, name: String, role: ShellRole, detail: String, _ db: MrasemDatabase) -> UserEntry {
        UserEntry(ref: ref, name: name, role: role, detail: detail,
                  unread: db.unreadCount(for: ref), isCurrent: db.currentUser == ref)
    }
}
