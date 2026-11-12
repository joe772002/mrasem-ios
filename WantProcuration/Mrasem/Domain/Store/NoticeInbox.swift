//
//  NoticeInbox.swift
//  Mrasem
//
//  Phase 16 — صندوق التنبيهات لأي مستخدم (مرافق / سائق)، الأحدث الأول بنص نهائي من الـ strings،
//  وأحدث تنبيه جديد للتوست اللحظي.
//

import Foundation

struct NoticeRow: Equatable, Identifiable {
    let id: String
    let text: String
    let createdAt: Date
    let isRead: Bool
}

struct NoticeInboxState: Equatable {
    let rows: [NoticeRow]
    let unread: Int

    static let empty = NoticeInboxState(rows: [], unread: 0)

    static func make(_ db: MrasemDatabase, user: UserRef?) -> NoticeInboxState {
        guard let user, db.exists(user) else { return .empty }
        let rows = db.notices(for: user).map { notice in
            NoticeRow(
                id: notice.id,
                text: mrasemNoticeText(NoticeContentMapper.content(notice.body, in: db)),
                createdAt: notice.createdAt,
                isRead: notice.readBy.contains(user)
            )
        }
        return NoticeInboxState(rows: rows, unread: rows.count { !$0.isRead })
    }
}

nonisolated enum LiveNotices {
    /// التنبيهات الجديدة (مش في `known`) للمستخدم، الأحدث الأول.
    static func fresh(_ db: MrasemDatabase, user: UserRef?, known: Set<String>) -> [NoticeRecord] {
        guard let user else { return [] }
        return db.notices(for: user).filter { !known.contains($0.id) }
    }
}
