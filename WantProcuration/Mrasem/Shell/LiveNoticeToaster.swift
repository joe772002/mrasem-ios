//
//  LiveNoticeToaster.swift
//  Mrasem
//
//  Phase 16 — الأحداث الحية: أي تنبيه جديد يوصل للمستخدم الحالي (من تغيير مستخدم تاني) بيظهر توست.
//  تبديل المستخدم بيصفّر الذاكرة، فتنبيهات المستخدم الجديد القديمة ما بتظهرش كأنها جديدة.
//

import Foundation
import Combine

nonisolated final class LiveNoticeToaster {
    private let toastBus: MrasemToastBus
    private var user: UserRef?
    private var known: Set<String>
    private var cancellable: AnyCancellable?

    init(store: MrasemStore, toastBus: MrasemToastBus) {
        self.toastBus = toastBus
        let db = store.database
        user = db.currentUser
        known = Self.ids(db, user)

        cancellable = store.publisher.sink { [weak self] in self?.receive($0) }
    }

    func receive(_ db: MrasemDatabase) {
        guard db.currentUser == user else {
            user = db.currentUser
            known = Self.ids(db, user)
            return
        }

        let fresh = LiveNotices.fresh(db, user: user, known: known)
        guard let newest = fresh.first else { return }
        known.formUnion(fresh.map(\.id))

        let text = mrasemNoticeText(NoticeContentMapper.content(newest.body, in: db))
        toastBus.show(ToastMessage(.res("mrasem_live_notice_strong"), .raw(text)))
    }

    private static func ids(_ db: MrasemDatabase, _ user: UserRef?) -> Set<String> {
        guard let user else { return [] }
        return Set(db.notices(for: user).map(\.id))
    }
}
