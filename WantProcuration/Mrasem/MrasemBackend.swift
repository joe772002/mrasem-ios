//
//  MrasemBackend.swift
//  Mrasem
//
//  Phase 13 — كل ما يخص البيانات المحلية في مكان واحد: القاعدة، الـ services، والمستودع اللي بتقرا منه الشاشات.
//  بتبقى تبديل المستخدم واختيار البداية (فارغ / بيانات العرض) هنا.
//

import Foundation
import Combine

nonisolated final class MrasemBackend {
    let store: MrasemStore
    let delegations: DelegationService
    let program: ProgramService
    let requests: RequestService
    let resources: ResourceService
    let trips: DriverTripService
    let guest: GuestService
    let repository: StoreMissionRepository
    /// تاريخ اليوم (بيتحقن في الاختبارات).
    let today: () -> MrasemDate

    init(
        storage: MrasemStorage = FileMrasemStorage(),
        now: @escaping () -> Date = { Date() },
        today: @escaping () -> MrasemDate = { MrasemDate.today() }
    ) {
        let store = MrasemStore(storage: storage)
        let program = ProgramService(store: store, now: now)
        let requests = RequestService(store: store, program: program, now: now)
        let trips = DriverTripService(store: store, now: now)

        self.store = store
        self.today = today
        self.program = program
        self.requests = requests
        self.trips = trips
        self.delegations = DelegationService(store: store, now: now)
        self.resources = ResourceService(store: store)
        self.guest = GuestService(store: store, requests: requests, now: now)
        self.repository = StoreMissionRepository(store: store, requests: requests, trips: trips, now: now, today: today)
    }

    var database: MrasemDatabase { store.database }

    /// أول تشغيل: «ابدأ فارغ» أو «حمّل بيانات العرض». بعدها يظهر «اختر المستخدم».
    func chooseStart(demo: Bool) {
        if demo { store.loadDemo() } else { store.startEmpty() }
        store.update { $0.currentUser = nil }
        repository.resetForNewUser()
    }

    /// تبديل المستخدم (من غير كلمة مرور — G6). تنبيهات اللي سبناه بتتعلّم مقروءة لأنه كان شايفها.
    func switchUser(to user: UserRef) {
        store.update { db in
            guard db.exists(user) else { return }
            if let previous = db.currentUser, previous != user {
                db.markAllRead(for: previous)
            }
            db.currentUser = user
        }
        repository.resetForNewUser()
    }

    /// «إعادة تحميل بيانات العرض»: يستبدل كل البيانات ببيانات العرض ويفضل المستخدم الحالي لو لسه موجود.
    func reloadDemo() {
        let user = store.database.currentUser
        store.loadDemo()
        store.update { db in
            db.currentUser = user.flatMap { db.exists($0) ? $0 : nil }
        }
        repository.resetForNewUser()
    }

    /// «مسح كل البيانات»: يرجّع التطبيق لأول تشغيل (سؤال البداية).
    func wipeAll() {
        store.wipeAll()
        repository.resetForNewUser()
    }
}
