//
//  AdminLogicTests.swift
//  WantProcurationTests
//
//  Phase 14 — منطق شاشات الأدمن (دوال صافية): لوحة التحكم، قائمة الوفود، تفاصيل الوفد.
//  بيانات العرض: d1 (نشط، ٣ أعضاء)، d2 (نشط)، d3 (مسودة). النهارده = ٢٠٢٦-١١-٢٤.
//

import XCTest
@testable import WantProcuration

final class AdminLogicTests: XCTestCase {

    private let today = "2026-11-24"
    private var demo: MrasemDatabase { MrasemSeed.demo() }

    // MARK: - لوحة التحكم

    func testHomeMovementsOfTodayWithConflictsAndDrivers() {
        let db = demo
        let state = AdminHomeBuilder.make(db, today: today)

        XCTAssertFalse(state.isEmpty)
        XCTAssertEqual(state.movements.map(\.id), ["p4", "p5", "p6", "s1", "p7"])
        XCTAssertEqual(state.movements.filter(\.hasConflict).map(\.id), ["p6", "s1"])
        XCTAssertEqual(state.movements[0].driverName, "أحمد")
        XCTAssertNil(state.movements[1].driverName, "p5 من غير سيارة")
        XCTAssertEqual(state.movements[0].delegationName, db.delegation("d1")?.name)
    }

    func testHomeActionsAreOrderedAndCounted() {
        let state = AdminHomeBuilder.make(demo, today: today)

        XCTAssertEqual(state.actions.map(\.kind), [.conflicts, .requests, .gaps, .gaps, .gaps])
        XCTAssertEqual(state.actions.map(\.count), [1, 3, 3, 3, 1])
        XCTAssertEqual(state.actions.filter { $0.kind == .gaps }.compactMap(\.delegationId), ["d1", "d3", "d2"])
        XCTAssertEqual(Set(state.actions.map(\.id)).count, state.actions.count, "كل بند له معرّف مختلف")
    }

    func testHomeSkipsArchivedDelegations() {
        var db = demo
        db.delegations[2].status = .archived

        let state = AdminHomeBuilder.make(db, today: today)
        XCTAssertEqual(state.actions.filter { $0.kind == .gaps }.compactMap(\.delegationId), ["d1", "d2"])
        XCTAssertFalse(state.movements.contains { $0.id == "s1" })
        XCTAssertEqual(state.summary.activeDelegations, 2)
    }

    func testHomeOnEmptyDatabase() {
        let state = AdminHomeBuilder.make(MrasemDatabase.blank(), today: today)

        XCTAssertTrue(state.isEmpty)
        XCTAssertTrue(state.movements.isEmpty)
        XCTAssertTrue(state.actions.isEmpty)
        XCTAssertEqual(state.summary.activeDelegations, 0)
        XCTAssertEqual(state.summary.totalDrivers, 0)
    }

    func testHomeActionDisappearsOnceResolved() {
        let env = AllRolesTestEnv()
        XCTAssertTrue(env.requests.resolve("rq1"))

        let requests = AdminHomeBuilder.make(env.db, today: today).actions.first { $0.kind == .requests }
        XCTAssertEqual(requests?.count, 2)
    }

    // MARK: - قائمة الوفود

    func testDelegationRowsAreSortedByStart() {
        let rows = AdminDelegationList.rows(demo, filter: .all)
        XCTAssertEqual(rows.map(\.id), ["d1", "d3", "d2"])
    }

    func testFiltersAndCounts() {
        let db = demo
        XCTAssertEqual(AdminDelegationList.rows(db, filter: .active).map(\.id), ["d1", "d2"])
        XCTAssertEqual(AdminDelegationList.rows(db, filter: .draft).map(\.id), ["d3"])
        XCTAssertTrue(AdminDelegationList.rows(db, filter: .archived).isEmpty)

        let counts = AdminDelegationList.counts(db)
        XCTAssertEqual([counts[.all], counts[.active], counts[.draft], counts[.archived]], [3, 2, 1, 0])
    }

    func testRowDetails() throws {
        let db = demo
        let d1 = try XCTUnwrap(AdminDelegationList.rows(db, filter: .all).first { $0.id == "d1" })
        XCTAssertEqual(d1.memberCount, 3)
        XCTAssertEqual(d1.readiness, 80)
        XCTAssertEqual(d1.missing, 3)
        XCTAssertEqual(d1.status, .active)
        XCTAssertEqual(d1.hotelName, db.place("h1")?.name)

        let d3 = try XCTUnwrap(AdminDelegationList.rows(db, filter: .all).first { $0.id == "d3" })
        XCTAssertNil(d3.hotelName)
        XCTAssertEqual(d3.status, .draft)
    }

    // MARK: - تفاصيل الوفد

    func testDetailOfUnknownDelegationIsNil() {
        XCTAssertNil(AdminDelegationDetailBuilder.make(demo, id: "nope"))
    }

    func testDetailMembersAndAssignments() throws {
        let detail = try XCTUnwrap(AdminDelegationDetailBuilder.make(demo, id: "d1"))

        XCTAssertEqual(detail.members.map(\.id), ["m1", "m2", "m3"])
        let head = detail.members[0]
        XCTAssertTrue(head.isHead)
        XCTAssertTrue(head.isActivated)
        XCTAssertEqual(head.escortName, "سعيد المري")
        XCTAssertEqual(head.carLabel, "لكزس LS – أسود · 123456")
        XCTAssertEqual(head.driverName, "أحمد")
        XCTAssertEqual(head.room, "1204")

        let last = detail.members[2]
        XCTAssertFalse(last.isActivated)
        XCTAssertNil(last.escortName)
        XCTAssertNil(last.carLabel)
        XCTAssertNil(last.driverName)
    }

    func testDetailProgramGroupedByDay() throws {
        let detail = try XCTUnwrap(AdminDelegationDetailBuilder.make(demo, id: "d1"))

        XCTAssertEqual(detail.days.map(\.date), ["2026-11-23", "2026-11-24", "2026-11-25"])
        XCTAssertEqual(detail.days[1].items.map(\.id), ["p4", "p5", "p6", "p7"])
        XCTAssertEqual(detail.days[1].label, StoreTime.dayLabel("2026-11-24"))

        let key = detail.days[1].items[0]
        XCTAssertTrue(key.isKey)
        XCTAssertFalse(key.hasConflict)
        XCTAssertTrue(detail.days[1].items[2].hasConflict, "p6 مع s1")
    }

    func testDetailReadinessGapsAndRequests() throws {
        let detail = try XCTUnwrap(AdminDelegationDetailBuilder.make(demo, id: "d1"))

        XCTAssertEqual(detail.readiness, 80)
        XCTAssertEqual(detail.gaps.missingCount, 3)
        XCTAssertEqual(detail.hotelName, demo.place("h1")?.name)
        XCTAssertEqual(Set(detail.requests.map(\.id)), ["rq1", "rq2", "rq3"])
        XCTAssertEqual(detail.requests.first { $0.id == "rq3" }?.status, .done)
        XCTAssertEqual(detail.requests.first { $0.id == "rq2" }?.kind, .question)
        XCTAssertEqual(detail.requests.first { $0.id == "rq1" }?.memberName, demo.member("m1")?.name)
    }

    func testDetailOfDelegationWithoutProgramOrMembers() throws {
        var db = MrasemDatabase.blank()
        db.delegations = [DelegationDraft(start: "2026-11-24", end: "2026-11-25").withName("وفد").record()]
        db.delegations[0].id = "x"

        let detail = try XCTUnwrap(AdminDelegationDetailBuilder.make(db, id: "x"))
        XCTAssertTrue(detail.members.isEmpty)
        XCTAssertTrue(detail.days.isEmpty)
        XCTAssertTrue(detail.requests.isEmpty)
        XCTAssertNil(detail.hotelName)
    }

    func testCarLabelWithoutPlate() {
        let db = demo
        XCTAssertEqual(AdminDelegationDetailBuilder.carLabel(db.car("c3")), "سيارة احتياطية")
        XCTAssertNil(AdminDelegationDetailBuilder.carLabel(nil))
    }
}

extension DelegationDraft {
    /// مساعد للاختبارات.
    func withName(_ name: String) -> DelegationDraft {
        var copy = self
        copy.name = name
        return copy
    }
}
