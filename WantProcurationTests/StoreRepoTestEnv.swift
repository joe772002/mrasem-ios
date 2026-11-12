//
//  StoreRepoTestEnv.swift
//  WantProcurationTests
//
//  Phase 13 — بيئة اختبار للمستودع المبني على القاعدة: backend في الذاكرة + ساعة ويوم ثابتين.
//

import Foundation
@testable import WantProcuration

final class StoreRepoEnv {
    let backend: MrasemBackend

    var repo: StoreMissionRepository { backend.repository }
    var db: MrasemDatabase { backend.database }
    var state: MrasemState { repo.state }

    /// النهارده = ٢٤ نوفمبر ٢٠٢٦ (اليوم الثاني من الوفد الأول).
    static let today = MrasemDate(year: 2026, month: 11, day: 24)

    init(demo: Bool = true, user: UserRef? = .member("m1")) {
        backend = MrasemBackend(
            storage: InMemoryMrasemStorage(),
            now: { AllRolesTestEnv.clock },
            today: { StoreRepoEnv.today }
        )
        backend.chooseStart(demo: demo)
        if let user { backend.switchUser(to: user) }
    }

    func act(as user: UserRef) {
        backend.switchUser(to: user)
    }

    /// تنبيهات القاعدة من نوع معيّن بالترتيب.
    func notices(where matches: (NoticeBody) -> Bool) -> [NoticeRecord] {
        db.notices.filter { matches($0.body) }
    }
}
