//
//  BusinessReviewTests.swift
//  MrasemTests
//
//  مراجعة البيزنيس (2026-11-15): السائق لازم يشوف وصول الوفد ورحلاته ووفوده، والأرقام لاتينية.
//  Mirrors Android: BusinessReviewTest.kt
//

import XCTest
@testable import WantProcuration

final class BusinessReviewTests: XCTestCase {

    func testGuestArrivalReachesTheDriver() {
        let env = AllRolesTestEnv()
        // الضيف (رئيس الوفد) هو اللي بيعلّم «وصلنا المطار»: السائق لازم يوصله تنبيه.
        env.act(as: .member("m1"))
        XCTAssertTrue(env.trips.setStatus("p1", .arrived))
        let notice = env.db.notices.last
        XCTAssertEqual(notice?.body, .tripStatus(itemId: "p1", status: .arrived))
        XCTAssertEqual(notice?.recipients.contains(.driver("r1")), true)
        XCTAssertEqual(notice?.recipients.contains(.member("m1")), false, "صاحب الفعل مستثنى")
    }

    func testDriverSeesNextDayWhenTodayIsEmpty() {
        let env = AllRolesTestEnv()
        let home = DriverHomeState.make(env.db, driverId: "r1", today: "2026-11-15")
        XCTAssertTrue(home.isUpcoming)
        XCTAssertEqual(home.date, "2026-11-23")
        XCTAssertFalse(home.rows.isEmpty)
        XCTAssertEqual(home.rows.first?.from, "")
        XCTAssertFalse(DriverHomeState.make(env.db, driverId: "r1", today: "2026-11-23").isUpcoming)
    }

    func testDriverSeesAssignedDelegationsEvenWithoutProgram() {
        let env = AllRolesTestEnv()
        env.store.update { $0.program = [] }
        let home = DriverHomeState.make(env.db, driverId: "r1", today: "2026-11-15")
        XCTAssertTrue(home.rows.isEmpty)
        XCTAssertEqual(home.assignments.map(\.id), ["d1", "d3"])
        XCTAssertEqual(home.assignments.first?.passengers.count, 2)
        XCTAssertTrue(DriverHomeState.make(env.db, driverId: "r1", today: "2027-01-01").assignments.isEmpty, "وفد خلص ما يظهرش")
    }

    func testNewMemberOnACarNotifiesDriverAndEscort() throws {
        let env = AllRolesTestEnv()
        env.act(as: .team("u1"))
        var member = try XCTUnwrap(env.db.member("m3"))
        member.id = ""
        member.name = "عضو جديد"
        member.carId = "c1"
        member.escortId = "e1"
        member.isHead = false
        let saved = try XCTUnwrap(env.delegations.saveMember(member).successValue)
        let notice = try XCTUnwrap(env.db.notices.last)
        XCTAssertEqual(notice.body, .assignmentChanged(memberId: saved.id))
        XCTAssertEqual(Set(notice.recipients), [.driver("r1"), .escort("e1")])
    }

    func testAddToProgramTellsTheDriverAndTheRestOfTheDelegation() throws {
        let env = AllRolesTestEnv()
        env.act(as: .team("u1"))
        let item = try XCTUnwrap(env.requests.addToProgram("rq1", date: "2026-11-25", time: "16:00", carId: "c1").successValue)
        let changed = try XCTUnwrap(env.db.notices.first { $0.body == .programChanged(itemId: item.id) })
        XCTAssertFalse(changed.recipients.contains(.member("m1")), "صاحب الطلب بيوصله «تم الترتيب» بس")
        XCTAssertTrue(changed.recipients.contains(.member("m2")))
        XCTAssertTrue(changed.recipients.contains(.driver("r1")))
    }

    func testDemoDataCanStartToday() {
        let db = MrasemSeed.demo(start: "2026-11-15")
        XCTAssertEqual(db.delegation("d1")?.start, "2026-11-15")
        XCTAssertEqual(db.delegation("d1")?.end, "2026-11-17")
        XCTAssertEqual(db.programItem("p1")?.date, "2026-11-15")
        XCTAssertTrue(db.program.allSatisfy { item in
            guard let delegation = db.delegation(item.delegationId) else { return false }
            return item.date >= delegation.start && item.date <= delegation.end
        })
        XCTAssertFalse(DriverHomeState.make(db, driverId: "r1", today: "2026-11-15").isUpcoming)
        XCTAssertEqual(MrasemSeed.demo(start: MrasemSeed.baseStart), MrasemSeed.demo())
    }

    func testEscortSeesTripStatus() {
        let env = AllRolesTestEnv()
        env.act(as: .driver("r1"))
        env.trips.setStatus("p1", .onTheWay)
        let card = EscortHomeState.make(env.db, escortId: "e1", today: "2026-11-23").delegations.first { $0.id == "d1" }
        XCTAssertEqual(card?.today.first { $0.id == "p1" }?.status, .onTheWay)
        XCTAssertNil(card?.today.first { $0.id == "p3" }?.status)
        XCTAssertEqual(card?.isUpcoming, false)
    }

    func testDigitsAreLatin() {
        XCTAssertEqual("٠٩:٣٠".toLatinDigits(), "09:30")
        XCTAssertEqual("۱۲".toLatinDigits(), "12")
        XCTAssertEqual(12.toLatinDigits(), "12")
        XCTAssertEqual(3.5.toLatinNumber(), "3.5")
        XCTAssertEqual(StoreTime.dayLabel("2026-11-23").last, "3")
    }
}
