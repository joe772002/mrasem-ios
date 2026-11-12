//
//  StoreMissionRepositoryTests.swift
//  WantProcurationTests
//
//  Phase 13 — الشاشات القديمة (ضيف / فريق) بتقرا وتكتب في القاعدة للمستخدم الحالي،
//  والتنبيه بيوصل للمعنيين بس ومرة واحدة.
//

import XCTest
@testable import WantProcuration

final class StoreMissionRepositoryTests: XCTestCase {

    // MARK: - القراءة

    func testMemberSeesOwnDelegationMission() {
        let env = StoreRepoEnv(user: .member("m1"))
        let state = env.state

        XCTAssertEqual(state.role, .guest)
        XCTAssertEqual(state.mode, .inbound)
        XCTAssertEqual(state.mission.guest, env.db.delegation("d1")?.name)
        XCTAssertEqual(state.mission.days.count, 3)
        XCTAssertEqual(state.mission.receiver.name, "سعيد المري")
        XCTAssertEqual(state.mission.car.plate, "123456")
        XCTAssertEqual(state.dress, .formal)
    }

    func testDefaultDayIsTodayInsideTheDelegationPeriod() {
        let env = StoreRepoEnv(user: .member("m1"))
        XCTAssertEqual(env.state.dayIndex, 1)

        env.repo.setDay(2)
        XCTAssertEqual(env.state.dayIndex, 2)
    }

    func testCoordinatorSelectsBetweenHisDelegations() {
        let env = StoreRepoEnv(user: .team("u2"))

        XCTAssertEqual(env.state.role, .team)
        XCTAssertEqual(env.state.mode, .inbound)
        XCTAssertEqual(env.repo.scope.delegationId, "d1")

        env.repo.selectDelegation("d2")
        XCTAssertEqual(env.state.mode, .outbound)
        XCTAssertEqual(env.state.mission.guest, env.db.delegation("d2")?.name)

        // تبديل المستخدم بيرجّع الاختيار للأول.
        env.act(as: .team("u2"))
        XCTAssertEqual(env.repo.scope.delegationId, "d1")
    }

    func testTeamSeesAllRequestsAndMemberSeesOwn() {
        let env = StoreRepoEnv(user: .team("u2"))
        XCTAssertEqual(env.state.requests.count, 3)

        env.act(as: .member("m2"))
        XCTAssertEqual(env.state.requests.count, 1)
        XCTAssertEqual(env.state.requests.first?.text, "هل يمكن تأجيل جولة المتحف ساعة؟")
        XCTAssertNil(env.state.requests.first?.place)
    }

    func testReferenceContentComesFromTheDestination() {
        let env = StoreRepoEnv(user: .member("m1"))
        let destination = env.db.destination("dest_doha")

        XCTAssertEqual(env.state.reference.checklist, destination?.checklist)
        XCTAssertFalse(env.state.reference.dressSet(.formal).title.isEmpty)

        let content = ProtocolStrategy(repository: env.repo).content()
        XCTAssertEqual(content.checklist.count, destination?.checklist.count)
        XCTAssertEqual(content.dress, env.state.reference.dressSet(.formal))
    }

    func testChangedMarksFollowTheDatabase() {
        let env = StoreRepoEnv(user: .team("u2"))
        XCTAssertTrue(env.state.changed.isEmpty)

        XCTAssertNotNil(ProgramStrategy(repository: env.repo).postponeKeyItem())
        XCTAssertTrue(env.state.changed.contains(.item(mode: .inbound, dayIndex: 1, itemIndex: 0)))
    }

    // MARK: - الكتابة والتنبيهات

    func testMemberRequestReachesCoordinatorAndAdmin() {
        let env = StoreRepoEnv(user: .member("m2"))
        let explore = ExploreStrategy(repository: env.repo)

        XCTAssertTrue(explore.requestVisit("سوق واقف"))
        XCTAssertEqual(env.db.requests.count, 5)
        XCTAssertEqual(env.db.requests.last?.memberId, "m2")
        XCTAssertNotNil(env.db.requests.last?.placeId)

        XCTAssertEqual(env.db.unreadCount(for: .team("u2")), 1)
        XCTAssertEqual(env.db.unreadCount(for: .team("u1")), 1)
        XCTAssertEqual(env.db.unreadCount(for: .member("m2")), 1)
        // نفس المكان تاني ما ينفعش.
        XCTAssertFalse(explore.requestVisit("سوق واقف"))
    }

    func testResolveRequestNotifiesTheMemberOnce() throws {
        let env = StoreRepoEnv(user: .team("u2"))
        let pending = try XCTUnwrap(env.state.requests.first { $0.status == .new && $0.place != nil })

        XCTAssertTrue(TeamStrategy(repository: env.repo).resolveRequest(pending.id))

        let resolved = env.notices { if case .requestResolved = $0 { return true } else { return false } }
        XCTAssertEqual(resolved.count, 1)
        XCTAssertTrue(resolved[0].recipients.contains(.member("m1")))
        XCTAssertFalse(resolved[0].recipients.contains(.team("u2")))
    }

    func testBroadcastGoesToTheDelegationMembersOnly() {
        let env = StoreRepoEnv(user: .team("u2"))
        XCTAssertTrue(TeamStrategy(repository: env.repo).broadcast("اجتماع الساعة العاشرة"))

        XCTAssertEqual(env.db.notices.last?.body, .broadcast("اجتماع الساعة العاشرة"))
        XCTAssertEqual(Set(env.db.notices.last?.recipients ?? []), [.member("m1"), .member("m2"), .member("m3")])
    }

    func testVisitSaveUpdatesRecordsAndNotifiesTheGuest() throws {
        let env = StoreRepoEnv(user: .team("u2"))
        let visit = VisitUpdateStrategy(repository: env.repo)
        let current = visit.currentForm()

        var data = current.data
        data.receiverName = "مرافق جديد"
        data.carPlate = "999"
        data.driver = "سائق جديد"
        data.hall = "قاعة ٢"

        XCTAssertEqual(visit.save(VisitForm(data: data, dress: .bisht)), .saved(sections: [.receiver, .car, .venue], dressChanged: true))
        XCTAssertEqual(env.db.escort("e1")?.name, "مرافق جديد")
        XCTAssertEqual(env.db.car("c1")?.plate, "999")
        XCTAssertEqual(env.db.driver("r1")?.name, "سائق جديد")
        XCTAssertEqual(env.db.place("g1")?.hall, "قاعة ٢")
        XCTAssertEqual(env.db.delegation("d1")?.dress, .bisht)

        let sent = env.notices { $0 == .dressApproved(.bisht) }
        XCTAssertEqual(sent.count, 1)
        XCTAssertTrue(sent[0].recipients.contains(.member("m1")))
        XCTAssertTrue(sent[0].recipients.contains(.escort("e1")))
        XCTAssertFalse(sent[0].recipients.contains(.team("u2")))

        // وبعدها الضيف يشوف البيانات الجديدة والعلامات والتنبيه.
        env.act(as: .member("m1"))
        XCTAssertEqual(env.state.mission.receiver.name, "مرافق جديد")
        XCTAssertEqual(env.state.mission.car.driver, "سائق جديد")
        XCTAssertTrue(env.state.notices.contains { $0.content == .dressApproved(.bisht) })
    }

    func testVisitSaveCreatesMissingRecords() {
        let env = StoreRepoEnv(user: .team("u2"))
        // وفد d3 من غير مرافق ولا سيارة ولا قاعة، ورئيسه m6 (ليه سيارة c1 في البيانات).
        env.backend.store.update { db in
            for i in db.members.indices where db.members[i].delegationId == "d3" { db.members[i].carId = nil }
            db.delegations[db.delegations.firstIndex { $0.id == "d3" }!].coordinatorIds = ["u2"]
        }
        env.repo.selectDelegation("d3")

        let visit = VisitUpdateStrategy(repository: env.repo)
        var data = visit.currentForm().data
        data.receiverName = "مرافق"
        data.receiverPhone = "123"
        data.carType = "سيارة"
        data.carPlate = "55"
        data.driver = "سائق"
        data.hall = "قاعة"

        XCTAssertEqual(visit.save(VisitForm(data: data, dress: .formal)), .saved(sections: [.receiver, .car, .venue], dressChanged: false))

        let state = env.state
        XCTAssertEqual(state.mission.receiver.name, "مرافق")
        XCTAssertEqual(state.mission.car.type, "سيارة")
        XCTAssertEqual(state.mission.car.driver, "سائق")
        XCTAssertEqual(state.mission.venue.hall, "قاعة")
        // السجلات الجديدة اتربطت بالوفد ده بس.
        XCTAssertEqual(env.db.member("m6")?.escortId, env.db.escorts.last?.id)
        XCTAssertEqual(env.db.member("m1")?.escortId, "e1")
    }

    func testPostponeNotifiesMembersEscortsAndDrivers() throws {
        let env = StoreRepoEnv(user: .team("u2"))
        let result = try XCTUnwrap(ProgramStrategy(repository: env.repo).postponeKeyItem())

        XCTAssertEqual(result.newTime, "10:00")
        XCTAssertEqual(env.db.programItem("p4")?.time, "10:00")
        XCTAssertEqual(env.db.programItem("p4")?.isChanged, true)

        let sent = env.notices { if case .postponed = $0 { return true } else { return false } }
        XCTAssertEqual(sent.count, 1)
        let recipients = Set(sent[0].recipients)
        XCTAssertTrue(recipients.isSuperset(of: [.member("m1"), .escort("e1"), .driver("r1")]))
        XCTAssertFalse(recipients.contains(.team("u2")))
    }

    func testArrivalFollowsTheFirstTripStatus() {
        let env = StoreRepoEnv(user: .member("m1"))
        let summary = MissionSummaryStrategy(repository: env.repo, now: { StoreRepoEnv.today })

        XCTAssertEqual(summary.advanceArrival(), 1)
        XCTAssertEqual(DriverTripService.status(of: "p1", in: env.db), .onTheWay)
        XCTAssertEqual(env.state.arrived(), 1)

        XCTAssertEqual(summary.advanceArrival(), 2)
        XCTAssertEqual(env.state.arrived(), 2)

        // اللي بيتابع بيستلم التنبيه، والعضو نفسه لأ.
        XCTAssertGreaterThan(env.db.unreadCount(for: .team("u2")), 0)
        XCTAssertEqual(env.db.unreadCount(for: .member("m2")), 3)
        XCTAssertEqual(env.db.notices(for: .member("m1")).count, 1)

        env.act(as: .member("m2"))
        let trip = env.state.notices.compactMap { notice -> TripStatus? in
            if case let .tripStatus(status, _) = notice.content { return status }
            return nil
        }
        XCTAssertEqual(trip, [.onTheWay, .arrived])
        XCTAssertEqual(env.state.arrived(), 2)
    }

    func testTripNoticeShowsTheDriverName() {
        let env = StoreRepoEnv(user: .team("u2"))
        env.backend.trips.setStatus("p1", .arrived)
        env.act(as: .member("m2"))

        let content = env.state.notices.last?.content
        XCTAssertEqual(content, .tripStatus(.arrived, driver: "أحمد"))
        XCTAssertEqual(mrasemNoticeText(.tripStatus(.arrived, driver: "أحمد")), "وصل السائق أحمد وهو في انتظارك.")
    }

    func testChecklistAndChatAreSavedPerMember() {
        let env = StoreRepoEnv(user: .member("m1"))
        ProtocolStrategy(repository: env.repo).toggleCheck(0)
        XCTAssertEqual(env.state.checks(), [0])

        let assistant = AssistantStrategy(repository: env.repo)
        XCTAssertNotNil(assistant.ask("ماذا ألبس اليوم؟"))
        XCTAssertEqual(env.state.chat.count, 2)
        XCTAssertEqual(assistant.conversation().count, 3)

        env.act(as: .member("m2"))
        XCTAssertTrue(env.state.checks().isEmpty)
        XCTAssertTrue(env.state.chat.isEmpty)
    }

    func testUnansweredQuestionBecomesARequestForTheCoordinator() {
        let env = StoreRepoEnv(user: .member("m1"))
        let before = env.db.requests.count

        _ = AssistantStrategy(repository: env.repo).ask("هل يوجد مسبح؟")

        XCTAssertEqual(env.db.requests.count, before + 1)
        XCTAssertEqual(env.db.requests.last?.kind, .question)
        XCTAssertEqual(env.db.unreadCount(for: .team("u2")), 1)
    }

    // MARK: - الحالات الفاضية

    func testEmptyDatabaseIsSafeForEveryStrategy() {
        let env = StoreRepoEnv(demo: false, user: .team(MrasemSeed.defaultAdmin.id))
        let state = env.state

        XCTAssertEqual(state.mission.days.count, 1)
        XCTAssertTrue(state.requests.isEmpty)
        XCTAssertTrue(state.notices.isEmpty)
        XCTAssertTrue(state.reference.checklist.isEmpty)

        _ = MissionSummaryStrategy(repository: env.repo, now: { StoreRepoEnv.today }).summary()
        XCTAssertTrue(ProgramStrategy(repository: env.repo).timeline().entries.isEmpty)
        XCTAssertEqual(TeamStrategy(repository: env.repo).kpis().newRequests, 0)
        XCTAssertNil(ProgramStrategy(repository: env.repo).postponeKeyItem())
        XCTAssertEqual(ProtocolStrategy(repository: env.repo).content().checklist.count, 0)
        XCTAssertEqual(AssistantStrategy(repository: env.repo).conversation().count, 1)
    }

    func testDeletingTheDelegationClearsTheMembersView() {
        let env = StoreRepoEnv(user: .team("u1"))
        XCTAssertTrue(env.backend.delegations.delete("d1"))
        env.act(as: .member("m4"))

        XCTAssertEqual(env.state.mode, .outbound)
        XCTAssertEqual(env.state.mission.guest, env.db.delegation("d2")?.name)

        // عضو اتحذف: مفيش مستخدم حالي ولا وفد.
        XCTAssertTrue(env.backend.delegations.deleteMember("m4"))
        XCTAssertNil(env.db.currentUser)
        XCTAssertEqual(env.state.mission.guest, "")
        XCTAssertEqual(env.repo.scope, ViewScope.none)
    }
}
