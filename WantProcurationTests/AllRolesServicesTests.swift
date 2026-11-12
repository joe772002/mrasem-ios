//
//  AllRolesServicesTests.swift
//  WantProcurationTests
//
//  Phase 12 — منطق الأعمال المشترك: الوقت، حسابات البوابة، البرنامج، الطلبات، الوفود، الموارد، رحلات السائق،
//  وتوزيع التنبيهات على المستخدمين المعنيين بس (G4).
//

import XCTest
@testable import WantProcuration

final class AllRolesServicesTests: XCTestCase {

    // MARK: - الوقت

    func testStoreTime() {
        XCTAssertEqual(StoreTime.add("23:50", minutes: 30), "00:20")
        XCTAssertEqual(StoreTime.add("09:30", minutes: -25), "09:05")
        XCTAssertNil(StoreTime.minutes("25:00"))
        XCTAssertNil(StoreTime.minutes("9:5"))
        XCTAssertEqual(StoreTime.days(from: "2026-11-30", to: "2026-12-02"), ["2026-11-30", "2026-12-01", "2026-12-02"])
        XCTAssertEqual(StoreTime.days(from: "2026-12-02", to: "2026-11-30"), [])
        XCTAssertFalse(StoreTime.isValidDate("2026-02-30"))
        XCTAssertEqual(StoreTime.dayLabel("2026-11-23"), "الإثنين ٢٣")
    }

    // MARK: - حسابات البوابة

    func testInsightsMatchPortal() {
        let db = AllRolesTestEnv().db

        let conflicts = PortalInsights.conflicts(db)
        XCTAssertEqual(conflicts.count, 1, "s1 (d3) و p6 (d1) نفس السائق بفرق ١٥ دقيقة")
        XCTAssertEqual(conflicts.first?.driver.id, "r1")
        XCTAssertEqual(PortalInsights.conflictItemIds(db), ["p6", "s1"])

        let gaps = PortalInsights.gaps(db, delegationId: "d1")
        XCTAssertEqual([gaps.noCar, gaps.noRoom, gaps.noEscort, gaps.total], [1, 1, 1, 3])
        XCTAssertEqual(PortalInsights.readiness(db, delegationId: "d1"), 80)

        let summary = PortalInsights.dashboard(db)
        XCTAssertEqual(summary.activeDelegations, 3)
        XCTAssertEqual(summary.inbound, 2)
        XCTAssertEqual(summary.members, 6)
        XCTAssertEqual(summary.activatedMembers, 3)
        XCTAssertEqual(summary.availableDrivers, 3)
        XCTAssertEqual([summary.newRequests, summary.newVisitRequests, summary.newQuestions], [3, 1, 2])

        XCTAssertEqual(PortalInsights.movements(db, on: "2026-11-24").map(\.id), ["p4", "p5", "p6", "s1", "p7"])
    }

    // MARK: - البرنامج

    func testPostponeNotifiesDelegationEscortAndDriver() {
        let env = AllRolesTestEnv()
        env.act(as: .team("u2"))

        XCTAssertEqual(env.program.postpone("p4"), "10:00")
        XCTAssertEqual(env.db.programItem("p4")?.time, "10:00")
        XCTAssertTrue(env.db.programItem("p4")?.isChanged ?? false)
        XCTAssertEqual(env.lastRecipients, [.member("m1"), .member("m2"), .member("m3"), .escort("e1"), .driver("r1")])
        XCTAssertEqual(env.lastNotice(for: .driver("r1")), .postponed(title: "جلسة المباحثات الرسمية", newTime: "10:00"))
    }

    func testProgramValidationAndSingleKeyItem() {
        let env = AllRolesTestEnv()
        var item = env.db.programItem("p5")!

        item.date = "2026-12-01"
        XCTAssertEqual(env.program.save(item).failureValue, .dateOutsideDelegation)
        item.date = "2026-11-24"
        item.time = "25:00"
        XCTAssertEqual(env.program.save(item).failureValue, .invalidTime)
        item.time = "11:30"
        item.title = "  "
        XCTAssertEqual(env.program.save(item).failureValue, .emptyName)

        item.title = "توقيع"
        item.isKey = true
        XCTAssertNotNil(env.program.save(item).successValue)
        XCTAssertEqual(env.db.program.filter { $0.delegationId == "d1" && $0.isKey }.map(\.id), ["p5"])
        XCTAssertTrue(env.db.programItem("p5")?.isChanged ?? false)
    }

    func testAutoNotifyOffSendsNothing() {
        let env = AllRolesTestEnv()
        env.resources.updatePreferences { $0.autoNotifyGuests = false }
        let before = env.db.notices.count

        var item = env.db.programItem("p7")!
        item.time = "18:00"
        env.program.save(item)
        XCTAssertEqual(env.db.notices.count, before)
    }

    // MARK: - الطلبات والتنبيهات

    func testRequestRoundTripBetweenMemberCoordinatorAndAdmin() throws {
        let env = AllRolesTestEnv()
        env.act(as: .member("m1"))
        let request = try XCTUnwrap(env.requests.create(memberId: "m1", kind: .visit, text: "كتارا", placeId: "a_inbound_4").successValue)
        XCTAssertEqual(env.lastRecipients, [.team("u2"), .team("u1")])

        env.act(as: .team("u2"))
        XCTAssertTrue(env.requests.resolve(request.id))
        XCTAssertFalse(env.requests.resolve(request.id), "منجز بالفعل")
        XCTAssertEqual(env.lastRecipients, [.member("m1"), .escort("e1")])
        XCTAssertEqual(env.lastNotice(for: .member("m1")), .requestResolved(requestId: request.id))
    }

    func testReplyAndAddToProgram() throws {
        let env = AllRolesTestEnv()
        env.act(as: .team("u1"))

        XCTAssertFalse(env.requests.reply("rq2", text: " "))
        XCTAssertTrue(env.requests.reply("rq2", text: "نعم، تم التأجيل"))
        XCTAssertEqual(env.db.requests.first { $0.id == "rq2" }?.reply, "نعم، تم التأجيل")
        XCTAssertEqual(env.lastNotice(for: .member("m2")), .requestReplied(requestId: "rq2"))

        let item = try XCTUnwrap(env.requests.addToProgram("rq1", date: "2026-11-25", time: "16:00").successValue)
        XCTAssertEqual(item.kind, .visit)
        XCTAssertEqual(item.placeId, env.db.requests.first { $0.id == "rq1" }?.placeId)
        XCTAssertEqual(env.db.requests.first { $0.id == "rq1" }?.status, .done)
    }

    func testBroadcastAudiences() {
        let env = AllRolesTestEnv()
        env.act(as: .team("u1"))

        XCTAssertTrue(env.requests.broadcast("تغيير المدخل", delegationId: "d1", audience: .drivers))
        XCTAssertEqual(env.lastRecipients, [.driver("r1")])
        XCTAssertTrue(env.requests.broadcast("تغيير المدخل", delegationId: "d1", audience: .escorts))
        XCTAssertEqual(env.lastRecipients, [.escort("e1")])
        XCTAssertTrue(env.requests.broadcast("تغيير المدخل", delegationId: "d2", audience: .all))
        XCTAssertEqual(env.lastRecipients, [.member("m4"), .member("m5")])
        XCTAssertFalse(env.requests.broadcast("  ", delegationId: "d1", audience: .all))
    }

    func testUnreadCountsPerUser() {
        let env = AllRolesTestEnv()
        XCTAssertEqual(env.db.unreadCount(for: .member("m1")), 1, "تنبيه العرض n1")

        env.act(as: .team("u1"))
        env.requests.broadcast("تنبيه", delegationId: "d1", audience: .all)
        XCTAssertEqual(env.db.unreadCount(for: .member("m1")), 2)
        XCTAssertEqual(env.db.unreadCount(for: .member("m4")), 0, "وفد تاني")
        XCTAssertEqual(env.db.unreadCount(for: .team("u1")), 0, "صاحب الفعل")

        env.store.update { $0.markAllRead(for: .member("m1")) }
        XCTAssertEqual(env.db.unreadCount(for: .member("m1")), 0)
    }

    // MARK: - الوفود والأعضاء

    func testDelegationValidationAndDressNotice() throws {
        let env = AllRolesTestEnv()
        env.act(as: .team("u1"))

        var draft = env.db.delegation("d3")!
        draft.id = ""
        draft.end = "2026-11-01"
        XCTAssertEqual(env.delegations.save(draft).failureValue, .endBeforeStart)
        draft.end = "2026-11-27"
        let created = try XCTUnwrap(env.delegations.save(draft).successValue)
        XCTAssertTrue(created.id.hasPrefix("d_"))

        var d1 = env.db.delegation("d1")!
        d1.dress = .bisht
        env.delegations.save(d1)
        XCTAssertEqual(env.lastRecipients, [.member("m1"), .member("m2"), .member("m3"), .escort("e1")])
        XCTAssertEqual(env.lastNotice(for: .member("m3")), .dressApproved(.bisht))
    }

    func testMemberAssignmentNotifiesOldAndNewDriver() throws {
        let env = AllRolesTestEnv()
        env.act(as: .team("u1"))

        var m2 = env.db.member("m2")!
        m2.carId = "c3"
        env.delegations.saveMember(m2)
        XCTAssertEqual(env.lastRecipients, [.member("m2"), .driver("r1"), .driver("r3"), .escort("e1")])

        var newMember = MemberRecord(id: "", delegationId: "d1", name: "عضو جديد", title: "", escortId: nil,
                                     carId: nil, room: "", appStatus: .invited, isHead: true)
        let saved = try XCTUnwrap(env.delegations.saveMember(newMember).successValue)
        XCTAssertEqual(env.db.members.filter { $0.delegationId == "d1" && $0.isHead }.map(\.id), [saved.id])

        newMember.name = ""
        XCTAssertEqual(env.delegations.saveMember(newMember).failureValue, .emptyName)
    }

    // MARK: - الموارد

    func testResources() throws {
        let env = AllRolesTestEnv()

        XCTAssertEqual(env.resources.saveDriver(DriverRecord(id: "", name: " ", phone: "", status: .available)).failureValue, .emptyName)
        let driver = try XCTUnwrap(env.resources.saveDriver(DriverRecord(id: "", name: "خالد", phone: "", status: .available)).successValue)
        XCTAssertTrue(driver.id.hasPrefix("r_"))
        XCTAssertNotNil(env.db.driver(driver.id))

        env.resources.assignDriver(driver.id, toCar: "c3")
        XCTAssertEqual(env.db.car("c3")?.driverId, driver.id)
        env.resources.assignDriver("missing", toCar: "c3")
        XCTAssertNil(env.db.car("c3")?.driverId)

        var admin = env.db.teamUser("u1")!
        admin.role = .viewer
        XCTAssertEqual(env.resources.saveTeamUser(admin).failureValue, .lastAdmin)
        XCTAssertFalse(env.resources.deleteTeamUser("u1"))
    }

    // MARK: - السائق

    func testDriverTripsAndArrivedReachesEveryoneConcerned() {
        let env = AllRolesTestEnv()

        let day = env.trips.trips(of: "r1", on: "2026-11-24")
        XCTAssertEqual(day.map(\.item.id), ["p4", "p6", "s1", "p7"])
        XCTAssertEqual(day[0].pickupTime, "09:05")
        XCTAssertEqual(day[0].arrivalTime, "09:15")
        XCTAssertEqual(day[0].passengers.map(\.id), ["m1", "m2"])
        XCTAssertEqual(day[1].from, env.db.place("g1")?.name, "بعد p4 في نفس اليوم")
        XCTAssertEqual(DriverTripService.dates(env.db, driverId: "r1"), ["2026-11-23", "2026-11-24", "2026-11-25"])

        env.act(as: .driver("r1"))
        XCTAssertTrue(env.trips.setStatus("p4", .arrived))
        XCTAssertFalse(env.trips.setStatus("p4", .arrived), "نفس الحالة")
        XCTAssertEqual(env.lastRecipients, [.member("m1"), .member("m2"), .escort("e1"), .team("u2"), .team("u1")])
        XCTAssertEqual(env.lastNotice(for: .member("m1")), .tripStatus(itemId: "p4", status: .arrived))
        XCTAssertEqual(DriverTripService.status(of: "p4", in: env.db), .arrived)
    }
}

extension Result {
    var successValue: Success? {
        if case let .success(value) = self { return value }
        return nil
    }

    var failureValue: Failure? {
        if case let .failure(error) = self { return error }
        return nil
    }
}
