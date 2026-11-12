//
//  GuestMissionAdapterTests.swift
//  WantProcurationTests
//
//  Phase 12 — `Mission` المبني من القاعدة لعضو لازم يطابق بيانات مراسم الأصلية (عشان شاشات الضيف ما تتغيرش
//  في Phase 13)، ومايقعش لو البيانات ناقصة. + أفعال الضيف (قائمة الفحص، طلب زيارة، المساعد).
//

import XCTest
@testable import WantProcuration

final class GuestMissionAdapterTests: XCTestCase {

    func testHeadMemberMissionMatchesOriginalInboundData() throws {
        let env = AllRolesTestEnv()
        let context = try XCTUnwrap(env.guest.context(memberId: "m1"))
        let mission = context.mission
        let original = MrasemDemoData.inbound

        XCTAssertEqual(mission.mode, .inbound)
        XCTAssertEqual(mission.guest, original.guest)
        XCTAssertEqual(mission.dest, original.dest)
        XCTAssertEqual(mission.start, original.start)
        XCTAssertEqual(mission.end, original.end)
        XCTAssertEqual(mission.receiver, original.receiver)
        XCTAssertEqual(mission.car, original.car)
        XCTAssertEqual(mission.venue, original.venue)
        XCTAssertEqual(mission.hotel, original.hotel, "بما فيها «٨ دقائق إلى الوزارة»")
        XCTAssertEqual(mission.emergency, original.emergency)
        XCTAssertEqual(mission.services, original.services)
        XCTAssertEqual(mission.quickInfo, original.quickInfo)
        XCTAssertEqual(mission.places, original.places)
        XCTAssertEqual(mission.customs, original.customs)
        XCTAssertEqual(mission.nextMeeting, original.nextMeeting)

        XCTAssertEqual(mission.days.map(\.label), ["الإثنين ٢٣", "الثلاثاء ٢٤", "الأربعاء ٢٥"])
        XCTAssertEqual(mission.days[1].items.count, 4)
        XCTAssertEqual(mission.days[1].items.first?.official?.isKey, true)
        XCTAssertEqual(context.itemIds[1], ["p4", "p5", "p6", "p7"])
        XCTAssertEqual(context.dressSet, MrasemDemoData.dressSets[.formal])
        XCTAssertEqual(context.checklist, MrasemDemoData.checklist)
    }

    func testOutboundHotelDriveUsesManyForm() throws {
        let env = AllRolesTestEnv()
        let mission = try XCTUnwrap(env.guest.context(memberId: "m4")).mission
        XCTAssertEqual(mission.hotel.drive, MrasemDemoData.outbound.hotel.drive)
        XCTAssertEqual(mission.car, MrasemDemoData.outbound.car)
    }

    func testIncompleteDelegationDoesNotCrash() throws {
        let env = AllRolesTestEnv()
        let context = try XCTUnwrap(env.guest.context(memberId: "m6"))
        XCTAssertEqual(context.mission.hotel.name, "")
        XCTAssertEqual(context.mission.hotel.drive, "")
        XCTAssertEqual(context.mission.receiver.name, "")
        XCTAssertEqual(context.mission.days.count, 3)
        XCTAssertNil(env.guest.context(memberId: "missing"))

        env.store.update { _ = $0.deleteDestination("dest_doha") }
        let bare = try XCTUnwrap(env.guest.context(memberId: "m1"))
        XCTAssertTrue(bare.mission.customs.isEmpty)
        XCTAssertTrue(bare.checklist.isEmpty)
    }

    func testArrivalStageFollowsFirstTrip() {
        let env = AllRolesTestEnv()
        XCTAssertEqual(env.guest.context(memberId: "m1")?.arrivalStage, 0)
        env.trips.setStatus("p1", .arrived)
        XCTAssertEqual(env.guest.context(memberId: "m1")?.arrivalStage, 2)
        env.trips.setStatus("p1", .completed)
        XCTAssertEqual(env.guest.context(memberId: "m2")?.arrivalStage, 4, "نفس الوفد")
        XCTAssertEqual(env.guest.context(memberId: "m4")?.arrivalStage, 0, "وفد تاني")
    }

    func testChangedProgramReachesGuestView() {
        let env = AllRolesTestEnv()
        env.program.postpone("p4")
        let first = env.guest.context(memberId: "m1")?.mission.days[1].items.first?.official
        XCTAssertEqual(first?.time, "10:00")
    }

    func testChecklistPerMember() {
        let env = AllRolesTestEnv()
        env.guest.toggleCheck(memberId: "m1", index: 0)
        env.guest.toggleCheck(memberId: "m1", index: 2)
        env.guest.toggleCheck(memberId: "m1", index: 99)
        XCTAssertEqual(env.guest.context(memberId: "m1")?.checked, [0, 2])
        XCTAssertEqual(env.guest.context(memberId: "m2")?.checked, [])

        env.guest.toggleCheck(memberId: "m1", index: 0)
        XCTAssertEqual(env.guest.context(memberId: "m1")?.checked, [2])
    }

    func testVisitRequestOncePerPlace() {
        let env = AllRolesTestEnv()
        env.act(as: .member("m2"))
        XCTAssertTrue(env.guest.requestVisit(memberId: "m2", placeId: "a_inbound_0"))
        XCTAssertFalse(env.guest.requestVisit(memberId: "m2", placeId: "a_inbound_0"))
        XCTAssertEqual(env.guest.visitRequestStatus(memberId: "m2", placeId: "a_inbound_0"), .new)
        XCTAssertNil(env.guest.visitRequestStatus(memberId: "m1", placeId: "a_inbound_0"))
    }

    func testAssistantAnswersFromDataAndForwardsUnknown() {
        let env = AllRolesTestEnv()
        env.act(as: .member("m1"))

        XCTAssertEqual(env.guest.ask(memberId: "m1", question: "ماذا ألبس اليوم؟"), .dress(.formal))
        let before = env.db.requests.count
        XCTAssertEqual(env.guest.ask(memberId: "m1", question: "xyz"), .forwarded)
        XCTAssertEqual(env.db.requests.count, before + 1)
        XCTAssertEqual(env.db.requests.last?.kind, .question)

        let chat = env.guest.conversation(memberId: "m1")
        XCTAssertEqual(chat.count, 5, "ترحيب + سؤالين وردين")
        XCTAssertEqual(env.guest.conversation(memberId: "m2").count, 1, "المحادثة لكل عضو")
    }
}
