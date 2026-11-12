//
//  Phase18Tests.swift
//  WantProcurationTests
//
//  Phase 18 — المراجعة: التعارضات على بيانات كبيرة (نفس نتيجة الطريقة القديمة)، تنبيه التعارض للأدمن،
//  والشاشات على بيانات كبيرة.
//

import XCTest
@testable import WantProcuration

final class Phase18Tests: XCTestCase {

    /// الطريقة القديمة (كل زوج مع كل زوج) كمرجع للمقارنة.
    private func bruteForceConflicts(_ db: MrasemDatabase) -> [DriverConflict] {
        let items = db.program.filter { $0.carId != nil }.sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
        var out: [DriverConflict] = []
        for i in items.indices {
            for j in items.indices where j > i {
                let a = items[i], b = items[j]
                guard a.date == b.date, a.delegationId != b.delegationId,
                      let da = PortalInsights.driver(of: a, in: db), let dbr = PortalInsights.driver(of: b, in: db), da.id == dbr.id,
                      let ta = StoreTime.minutes(a.time), let tb = StoreTime.minutes(b.time),
                      abs(ta - tb) < PortalInsights.conflictWindowMinutes
                else { continue }
                out.append(DriverConflict(first: a, second: b, driver: da))
            }
        }
        return out
    }

    /// قاعدة كبيرة: ٤٠ وفد × ٤٠ فقرة على ١٠ سيارات، بأوقات متقاربة فيها تعارضات كتير.
    private func bigDatabase() -> MrasemDatabase {
        var db = MrasemSeed.demo()
        for d in 0..<10 {
            db.drivers.append(DriverRecord(id: "bd\(d)", name: "سائق \(d)", phone: "", status: .available))
            db.cars.append(CarRecord(id: "bc\(d)", type: "سيارة \(d)", plate: "\(d)", plateStyle: .qatar, driverId: "bd\(d)"))
        }
        for d in 0..<40 {
            db.delegations.append(DelegationRecord(
                id: "bdel\(d)", name: "وفد \(d)", mode: .inbound, host: "", countryLabel: "", destinationId: nil,
                start: "2026-11-23", end: "2026-11-26", hotelId: nil, venueId: nil, coordinatorIds: [],
                status: .active, dress: .formal, nextMeeting: nil
            ))
            for i in 0..<40 {
                let minutes = 6 * 60 + ((d * 37 + i * 53) % (14 * 60))
                db.program.append(ProgramItemRecord(
                    id: "bp\(d)_\(i)", delegationId: "bdel\(d)", date: "2026-11-2\(3 + i % 4)",
                    time: StoreTime.format(minutes), endTime: nil, title: "فقرة \(i)", kind: .visit, placeId: nil,
                    note: "", carId: "bc\((d + i) % 10)", isKey: false, isChanged: false
                ))
            }
        }
        return db
    }

    func testConflictsMatchTheBruteForceResultOnBigData() {
        let db = bigDatabase()
        let fast = PortalInsights.conflicts(db)
        let slow = bruteForceConflicts(db)

        XCTAssertGreaterThan(slow.count, 0)
        XCTAssertEqual(fast.count, slow.count)
        XCTAssertEqual(Set(fast.map { $0.first.id + "|" + $0.second.id }), Set(slow.map { $0.first.id + "|" + $0.second.id }))
        XCTAssertEqual(PortalInsights.conflicts(MrasemSeed.demo()), bruteForceConflicts(MrasemSeed.demo()), "نفس الترتيب على بيانات العرض")
    }

    func testScreensBuildOnBigData() {
        let db = bigDatabase()
        let today = "2026-11-24"

        XCTAssertFalse(AdminHomeBuilder.make(db, today: today).actions.isEmpty)
        XCTAssertEqual(AdminDelegationList.rows(db, filter: .all).count, db.delegations.count)
        XCTAssertFalse(AdminResourcesState.make(db, today: today).assignments.isEmpty)
        XCTAssertFalse(DriverScheduleState.make(db, driverId: "bd0").days.isEmpty)

        measure {
            _ = AdminHomeBuilder.make(db, today: today)
            _ = AdminResourcesState.make(db, today: today)
        }
    }

    // MARK: - تنبيه التعارض

    func testNewConflictNotifiesAdmins() throws {
        let env = StoreRepoEnv(user: .team("u2"))
        // p6 (d1, 12:30, c1) و s1 (d3, 12:45, c1) متعارضين من الأول ← مش تنبيه جديد.
        let before = env.db.notices.count
        var p6 = try XCTUnwrap(env.db.programItem("p6"))
        p6.note = "ملاحظة"
        _ = try env.backend.program.save(p6, notify: false).get()
        XCTAssertEqual(env.db.notices.count, before)

        // فقرة جديدة في d3 بنفس السائق r1 (سيارة c1) قريبة من p4 (d1، 09:30) ← تعارض جديد.
        let item = ProgramItemRecord(
            id: "", delegationId: "d3", date: "2026-11-24", time: "09:45", endTime: nil, title: "زيارة متعارضة",
            kind: .visit, placeId: nil, note: "", carId: "c1", isKey: false, isChanged: false
        )
        let saved = try env.backend.program.save(item, notify: false).get()
        let conflictNotices = env.notices { $0 == .driverConflict(itemId: saved.id) }
        XCTAssertEqual(conflictNotices.count, 1)
        let recipients = Set(conflictNotices.first?.recipients ?? [])
        XCTAssertEqual(recipients, [.team("u1")], "الأدمن (d3 ملوش منسقين، والمنسق صاحب الفعل)")

        let text = mrasemNoticeText(NoticeContentMapper.content(.driverConflict(itemId: saved.id), in: env.db))
        XCTAssertTrue(text.contains("زيارة متعارضة"))
        XCTAssertTrue(text.contains(env.db.driver("r1")?.name ?? "-"))
    }

    func testConflictNoticeRespectsThePreference() throws {
        let env = StoreRepoEnv(user: .team("u2"))
        env.backend.resources.updatePreferences { $0.notifyConflict = false }
        let item = ProgramItemRecord(
            id: "", delegationId: "d3", date: "2026-11-24", time: "09:45", endTime: nil, title: "زيارة",
            kind: .visit, placeId: nil, note: "", carId: "c1", isKey: false, isChanged: false
        )
        let saved = try env.backend.program.save(item, notify: false).get()
        XCTAssertTrue(env.notices { $0 == .driverConflict(itemId: saved.id) }.isEmpty)
        XCTAssertFalse(NoticeContentMapper.isSentToGuest(.driverConflict(itemId: saved.id)))
    }
}
