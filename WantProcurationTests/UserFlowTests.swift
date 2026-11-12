//
//  UserFlowTests.swift
//  WantProcurationTests
//
//  Phase 13 — شاشة البداية، «اختر المستخدم»، التبديل، وتابات كل دور.
//

import XCTest
import Combine
@testable import WantProcuration

final class UserFlowTests: XCTestCase {

    // MARK: - قائمة المستخدمين

    func testPickerSectionsForTheDemoData() {
        let env = StoreRepoEnv(user: .team("u1"))
        let sections = UserDirectory.sections(env.db)

        XCTAssertEqual(sections.map(\.kind), [.team, .members, .escorts, .drivers])
        XCTAssertEqual(sections[0].entries.map(\.name), ["مريم الكعبي", "سعيد المري"])
        // أعضاء الوفد النشطين بس (m3 و m5 و m6 مدعوّين ولسه ما دخلوش).
        XCTAssertEqual(sections[1].entries.map { $0.ref }, [.member("m1"), .member("m2"), .member("m4")])
        XCTAssertEqual(sections[2].entries.count, 3)
        XCTAssertEqual(sections[3].entries.count, 4)
        XCTAssertEqual(sections[0].entries.first?.isCurrent, true)
        XCTAssertEqual(sections[0].entries.first?.role, .admin)
        XCTAssertEqual(sections[0].entries.last?.role, .coordinator)
    }

    func testMemberDetailShowsTitleAndDelegation() {
        let env = StoreRepoEnv(user: .team("u1"))
        let entry = UserDirectory.sections(env.db)[1].entries[0]

        XCTAssertTrue(entry.detail.contains("رئيس الوفد"))
        XCTAssertTrue(entry.detail.contains(env.db.delegation("d1")?.name ?? "؟"))
    }

    func testUnreadBadgesAndSwitchingMarksTheLeftUserRead() {
        let env = StoreRepoEnv(user: .member("m1"))
        XCTAssertEqual(env.db.unreadCount(for: .member("m1")), 1)

        env.act(as: .member("m2"))
        XCTAssertEqual(env.db.unreadCount(for: .member("m1")), 0)
        XCTAssertEqual(env.db.unreadCount(for: .member("m2")), 1)

        let entries = UserDirectory.sections(env.db)[1].entries
        XCTAssertEqual(entries.first { $0.ref == .member("m1") }?.unread, 0)
        XCTAssertEqual(entries.first { $0.ref == .member("m2") }?.unread, 1)
        XCTAssertEqual(entries.first { $0.ref == .member("m2") }?.isCurrent, true)
    }

    func testSwitchingToAUserThatDoesNotExistChangesNothing() {
        let env = StoreRepoEnv(user: .member("m1"))
        env.act(as: .member("ghost"))

        XCTAssertEqual(env.db.currentUser, .member("m1"))
        XCTAssertEqual(env.db.unreadCount(for: .member("m1")), 1)
    }

    func testEmptyStartHasOnlyTheAdmin() {
        let env = StoreRepoEnv(demo: false, user: nil)
        let state = UserPickerState.make(env.db)

        XCTAssertEqual(state.sections.map(\.kind), [.team])
        XCTAssertTrue(state.onlyOneUser)
        XCTAssertFalse(state.canGoBack)
        XCTAssertTrue(env.db.didChooseStart)
        XCTAssertNil(env.db.currentUser)
    }

    // MARK: - مراحل التطبيق

    func testFlowGoesFromStartToPickerToShellAndBack() {
        let backend = MrasemBackend(storage: InMemoryMrasemStorage())
        let flow = MrasemAppFlow(backend: backend)
        XCTAssertEqual(flow.stage, .chooseStart)

        flow.startChosen(demo: true)
        XCTAssertEqual(flow.stage, .pickUser)

        flow.userChosen(.member("m1"))
        XCTAssertEqual(flow.stage, .main)
        XCTAssertEqual(backend.database.currentUser, .member("m1"))

        flow.openPicker()
        XCTAssertEqual(flow.stage, .pickUser)
        flow.keepCurrentUser()
        XCTAssertEqual(flow.stage, .main)
    }

    func testFlowAsksForTheUserEveryLaunchButStartOnlyOnce() {
        let storage = InMemoryMrasemStorage()
        let first = MrasemBackend(storage: storage)
        let firstFlow = MrasemAppFlow(backend: first)
        firstFlow.startChosen(demo: false)
        firstFlow.userChosen(.team(MrasemSeed.defaultAdmin.id))
        XCTAssertEqual(firstFlow.stage, .main)

        // تشغيل جديد على نفس الملف: يعدّي سؤال البداية ويسأل عن المستخدم.
        let second = MrasemBackend(storage: storage)
        XCTAssertEqual(MrasemAppFlow(backend: second).stage, .pickUser)
        XCTAssertEqual(second.database.currentUser, .team(MrasemSeed.defaultAdmin.id))
    }

    func testWipingEverythingAsksForTheStartAgain() {
        let backend = MrasemBackend(storage: InMemoryMrasemStorage())
        let flow = MrasemAppFlow(backend: backend)
        flow.startChosen(demo: true)
        flow.userChosen(.member("m1"))

        backend.store.wipeAll()
        XCTAssertEqual(flow.stage, .chooseStart)
    }

    // MARK: - تابات الأدوار

    func testEveryRoleHasItsTabs() {
        XCTAssertEqual(RoleTab.tabs(for: .admin).count, 5)
        XCTAssertEqual(RoleTab.tabs(for: .coordinator), MrasemDestination.team.map { RoleTab.screen($0) })
        XCTAssertEqual(RoleTab.tabs(for: .member), MrasemDestination.guest.map { RoleTab.screen($0) })
        XCTAssertEqual(RoleTab.tabs(for: .escort).count, 2)
        XCTAssertEqual(RoleTab.tabs(for: .driver).count, 2)
    }

    func testRolesComeFromTheUserRecord() {
        let env = StoreRepoEnv(user: .team("u1"))
        XCTAssertEqual(ShellRole.of(.team("u1"), in: env.db), .admin)
        XCTAssertEqual(ShellRole.of(.team("u2"), in: env.db), .coordinator)
        XCTAssertEqual(ShellRole.of(.member("m1"), in: env.db), .member)
        XCTAssertEqual(ShellRole.of(.escort("e1"), in: env.db), .escort)
        XCTAssertEqual(ShellRole.of(.driver("r1"), in: env.db), .driver)
    }

    func testShellStateForEachRole() {
        let env = StoreRepoEnv(user: .member("m1"))
        var shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: nil)
        XCTAssertEqual(shell.role, .member)
        XCTAssertEqual(shell.selected, .screen(.mission))
        XCTAssertEqual(shell.tabs.count, 6)
        XCTAssertTrue(shell.delegations.isEmpty)
        XCTAssertTrue(shell.hasDelegation)
        XCTAssertEqual(shell.unread, 1)

        env.act(as: .team("u2"))
        shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: nil)
        XCTAssertEqual(shell.role, .coordinator)
        XCTAssertEqual(shell.selected, .screen(.teamVisit))
        XCTAssertEqual(shell.delegations.map(\.id), ["d1", "d2"])
        XCTAssertEqual(shell.selectedDelegationId, "d1")

        env.act(as: .team("u1"))
        shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: .admin(.places))
        XCTAssertEqual(shell.role, .admin)
        XCTAssertEqual(shell.selected, .admin(.places))
        XCTAssertEqual(shell.tabIndex, 3)
        XCTAssertFalse(shell.needsDelegation)

        env.act(as: .driver("r1"))
        shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: .admin(.places))
        XCTAssertEqual(shell.selected, .soon(.driverTrips))
    }

    func testTabSelectionChangesTheRightState() {
        let env = StoreRepoEnv(user: .member("m1"))
        let model = RoleShellModel(backend: env.backend, session: session(env.repo))

        model.select(.screen(.explore))
        XCTAssertEqual(model.uiState.selected, .screen(.explore))

        env.act(as: .team("u2"))
        model.select(.screen(.teamRequests))
        XCTAssertEqual(model.uiState.selected, .screen(.teamRequests))
        XCTAssertEqual(env.repo.nav.teamTab, .requests)

        model.select(delegation: "d2")
        XCTAssertEqual(model.uiState.selectedDelegationId, "d2")
    }

    func testCoordinatorWithoutDelegationNeedsOne() {
        let env = StoreRepoEnv(demo: false, user: nil)
        env.backend.store.update {
            $0.team.append(TeamUserRecord(id: "x", name: "منسق", role: .coordinator, phone: "", email: ""))
        }
        env.act(as: .team("x"))

        let shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: nil)
        XCTAssertTrue(shell.needsDelegation)
        XCTAssertFalse(shell.hasDelegation)
        XCTAssertTrue(shell.delegations.isEmpty)
    }

    // MARK: - النصوص

    func testNewStringKeysResolve() {
        var keys = RoleTab.tabs(for: .admin).map(\.labelKey)
        keys += RoleTab.tabs(for: .escort).map(\.labelKey) + RoleTab.tabs(for: .driver).map(\.labelKey)
        keys += ShellRole.allCases.map(\.labelKey) + UserSectionKind.allCases.map(\.titleKey)
        keys += ["mrasem_start_title", "mrasem_start_message", "mrasem_start_demo", "mrasem_start_demo_hint",
                 "mrasem_start_empty", "mrasem_start_empty_hint", "mrasem_start_footer",
                 "mrasem_users_title", "mrasem_users_subtitle", "mrasem_users_current", "mrasem_users_unread",
                 "mrasem_users_unread_a11y", "mrasem_users_back", "mrasem_users_empty_hint",
                 "mrasem_header_switch", "mrasem_header_delegation_label",
                 "mrasem_empty_scope_title", "mrasem_empty_scope_message", "mrasem_placeholder_phase",
                 "mrasem_notice_program_changed", "mrasem_notice_trip_on_the_way", "mrasem_notice_trip_arrived",
                 "mrasem_notice_trip_picked_up", "mrasem_notice_trip_completed", "mrasem_notice_trip_unknown_driver",
                 "mrasem_notice_request_created", "mrasem_notice_assignment_changed"]
        for key in keys {
            XCTAssertNotEqual(mrasemString(key), key, "missing string: \(key)")
        }
    }

    func testNewNoticeTexts() {
        XCTAssertEqual(mrasemNoticeText(.programChanged(title: "عشاء")), "تم تعديل فقرة \"عشاء\" في البرنامج.")
        XCTAssertEqual(mrasemNoticeText(.tripStatus(.onTheWay, driver: "أحمد")), "السائق أحمد في الطريق إليك.")
        XCTAssertEqual(mrasemNoticeText(.tripStatus(.pickedUp, driver: "أحمد")), "تم الاستلام مع السائق أحمد.")
        XCTAssertEqual(mrasemNoticeText(.tripStatus(.completed, driver: "أحمد")), "انتهت الرحلة مع السائق أحمد.")
        XCTAssertEqual(mrasemNoticeText(.requestCreated(text: "سوق واقف")), "طلب جديد من وفد: سوق واقف")
    }

    func testNoticeMapperCoversEveryBody() {
        let env = StoreRepoEnv(user: .team("u2"))
        let db = env.db
        let bodies: [NoticeBody] = [
            .broadcast("a"), .dressApproved(.bisht), .visitDataUpdated, .programChanged(itemId: "p4"),
            .postponed(title: "t", newTime: "10:00"), .requestCreated(requestId: "rq1"), .requestResolved(requestId: "rq1"),
            .requestResolved(requestId: "rq2"), .requestReplied(requestId: "rq2"), .tripStatus(itemId: "p1", status: .arrived),
            .assignmentChanged(memberId: "m1"), .programChanged(itemId: "missing"),
        ]
        let contents = bodies.map { NoticeContentMapper.content($0, in: db) }

        XCTAssertEqual(contents[3], .programChanged(title: "جلسة المباحثات الرسمية"))
        XCTAssertEqual(contents[6], .requestResolved(place: "سوق واقف"))
        XCTAssertEqual(contents[7], .requestResolved(place: nil))
        XCTAssertEqual(contents[9], .tripStatus(.arrived, driver: "أحمد"))
        // فقرة اتحذفت: نص عام بدل ما التنبيه يضيع.
        XCTAssertEqual(contents[11], .visitDataUpdated)
        XCTAssertFalse(NoticeContentMapper.isSentToGuest(.tripStatus(itemId: "p1", status: .arrived)))
        XCTAssertTrue(NoticeContentMapper.isSentToGuest(.broadcast("a")))
    }
}
