//
//  ViewScope.swift
//  Mrasem
//
//  Phase 13 — «المستخدم الحالي بيشوف إيه»: أي وفد وأي عضو. شاشات الضيف والفريق القديمة
//  بتشتغل على وفد واحد، فالنطاق ده هو اللي بيحدد الوفد ده (G5: ممكن يكون فاضي).
//

import Foundation

/// الدور اللي بيحدد التابات (خمس مجموعات، 08 §1).
enum ShellRole: String, CaseIterable, Hashable {
    case admin
    case coordinator
    case member
    case escort
    case driver

    static func of(_ user: UserRef, in db: MrasemDatabase) -> ShellRole {
        switch user {
        case let .team(id): return db.teamUser(id)?.role == .admin ? .admin : .coordinator
        case .member: return .member
        case .escort: return .escort
        case .driver: return .driver
        }
    }
}

struct ViewScope: Equatable {
    let user: UserRef?
    let delegationId: String?
    /// العضو نفسه (لمستخدم عضو بس).
    let memberId: String?

    static let none = ViewScope(user: nil, delegationId: nil, memberId: nil)

    /// الوفود اللي المستخدم يقدر يشتغل عليها (للمنسق والأدمن بيتختار منها، وللمرافق وفوده).
    static func delegations(for user: UserRef?, in db: MrasemDatabase) -> [DelegationRecord] {
        guard let user else { return [] }
        let list: [DelegationRecord]
        switch user {
        case let .team(id):
            if db.teamUser(id)?.role == .admin {
                list = db.delegations
            } else {
                list = db.delegations.filter { $0.coordinatorIds.contains(id) }
            }
        case let .member(id):
            list = db.delegation(db.member(id)?.delegationId).map { [$0] } ?? []
        case let .escort(id):
            list = ResourceService.delegations(ofEscort: id, in: db)
        case .driver:
            list = []
        }
        // الشغّالة الأول، وبعدها المسودة، والأرشيف في الآخر (الترتيب ثابت جوّه كل مجموعة).
        func rank(_ status: DelegationStatus) -> Int {
            switch status {
            case .active: return 0
            case .draft: return 1
            case .archived: return 2
            }
        }
        return list.enumerated()
            .sorted { (rank($0.element.status), $0.offset) < (rank($1.element.status), $1.offset) }
            .map(\.element)
    }

    static func resolve(_ db: MrasemDatabase, selected: String?) -> ViewScope {
        guard let user = db.currentUser, db.exists(user) else { return .none }

        if case let .member(id) = user, let member = db.member(id) {
            return ViewScope(user: user, delegationId: member.delegationId, memberId: id)
        }

        let options = delegations(for: user, in: db)
        let chosen = options.first { $0.id == selected } ?? options.first
        return ViewScope(user: user, delegationId: chosen?.id, memberId: nil)
    }
}
