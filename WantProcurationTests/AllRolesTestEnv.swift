//
//  AllRolesTestEnv.swift
//  WantProcurationTests
//
//  Phase 12 — بيئة اختبار مشتركة: قاعدة ببيانات العرض + كل الـ services + ساعة ثابتة.
//

import Foundation
@testable import WantProcuration

final class AllRolesTestEnv {
    let store: MrasemStore
    let delegations: DelegationService
    let program: ProgramService
    let requests: RequestService
    let resources: ResourceService
    let trips: DriverTripService
    let guest: GuestService

    static let clock = Date(timeIntervalSince1970: 1_800_000_000)

    init(demo: Bool = true) {
        store = MrasemStore(storage: InMemoryMrasemStorage())
        if demo { store.loadDemo() }

        let now: () -> Date = { AllRolesTestEnv.clock }
        delegations = DelegationService(store: store, now: now)
        program = ProgramService(store: store, now: now)
        requests = RequestService(store: store, program: program, now: now)
        resources = ResourceService(store: store)
        trips = DriverTripService(store: store, now: now)
        guest = GuestService(store: store, requests: requests, now: now)
    }

    var db: MrasemDatabase { store.database }

    /// يبدّل المستخدم الحالي (صاحب الفعل ما بيستلمش تنبيهه).
    func act(as user: UserRef?) {
        store.update { $0.currentUser = user }
    }

    /// آخر تنبيه وصل للمستخدم.
    func lastNotice(for user: UserRef) -> NoticeBody? {
        db.notices(for: user).first?.body
    }

    /// مستلمو آخر تنبيه اتبعت.
    var lastRecipients: Set<UserRef> {
        Set(db.notices.last?.recipients ?? [])
    }
}
