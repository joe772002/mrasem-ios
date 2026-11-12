//
//  Phase16Tests.swift
//  WantProcurationTests
//
//  Phase 16 — السائق والمرافق والأحداث الحية: رحلاتي وحالة الرحلة، الجدول، وفدي، صندوق التنبيهات، والتوست اللحظي.
//

import XCTest
import Combine
@testable import WantProcuration

final class Phase16Tests: XCTestCase {

    private let today = "2026-11-24"

    /// رحلة النهاردة على سيارة c1 (سائقها r1) عشان الاختبار مايعتمدش على تفاصيل البيانات.
    private func addTodayTrip(_ env: StoreRepoEnv) throws -> ProgramItemRecord {
        let item = ProgramItemRecord(
            id: "", delegationId: "d1", date: today, time: "23:00", endTime: nil, title: "عشاء اختبار", kind: .meal,
            placeId: nil, note: "", carId: "c1", isKey: false, isChanged: false
        )
        return try env.backend.program.save(item, notify: false).get()
    }

    // MARK: - الحالة

    func testTripStatusChain() {
        var chain: [TripStatus] = [.scheduled]
        while let next = chain.last?.next { chain.append(next) }
        XCTAssertEqual(chain, [.scheduled, .onTheWay, .arrived, .pickedUp, .completed])
        XCTAssertNil(TripStatus.completed.next)
    }

    // MARK: - السائق

    func testDriverHomeState() throws {
        let env = StoreRepoEnv(user: .driver("r1"))
        let trip = try addTodayTrip(env)
        let state = DriverHomeState.make(env.db, driverId: "r1", today: today)

        XCTAssertEqual(state.driverName, env.db.driver("r1")?.name)
        XCTAssertNotNil(state.carLabel)
        XCTAssertEqual(state.rows.count, DriverTripService.trips(env.db, driverId: "r1", on: today).count)
        let row = try XCTUnwrap(state.rows.first { $0.id == trip.id })
        XCTAssertEqual(row.status, .scheduled)
        XCTAssertEqual(row.next, .onTheWay)
        XCTAssertEqual(row.pickupTime, "22:35")
        XCTAssertEqual(row.arrivalTime, "22:45")
        XCTAssertEqual(DriverHomeState.make(env.db, driverId: "missing", today: today), .empty)
    }

    func testDriverScheduleGroupsByDay() throws {
        let env = StoreRepoEnv(user: .driver("r1"))
        _ = try addTodayTrip(env)
        let state = DriverScheduleState.make(env.db, driverId: "r1")

        XCTAssertEqual(state.days.map(\.date), state.days.map(\.date).sorted())
        XCTAssertTrue(state.days.contains { $0.date == today })
        XCTAssertTrue(state.days.allSatisfy { !$0.rows.isEmpty })
        XCTAssertEqual(state.days.flatMap(\.rows).count, DriverTripService.trips(env.db, driverId: "r1").count)
    }

    func testDriverModelAdvancesTripAndNotifies() throws {
        let env = StoreRepoEnv(user: .driver("r1"))
        let trip = try addTodayTrip(env)
        let model = DriverTripsModel(backend: env.backend)
        let adminBefore = env.db.unreadCount(for: .team("u1"))

        model.advance(trip.id)
        XCTAssertEqual(model.uiState.rows.first { $0.id == trip.id }?.status, .onTheWay)
        XCTAssertGreaterThan(env.db.unreadCount(for: .team("u1")), adminBefore, "الأدمن بيتبلّغ")

        for expected in [TripStatus.arrived, .pickedUp, .completed] {
            model.advance(trip.id)
            XCTAssertEqual(model.uiState.rows.first { $0.id == trip.id }?.status, expected)
        }
        model.advance(trip.id)
        XCTAssertEqual(model.uiState.rows.first { $0.id == trip.id }?.status, .completed)
        XCTAssertGreaterThanOrEqual(model.uiState.done, 1)

        model.advance("missing")
    }

    func testDriverModelsForNonDriverAreEmpty() {
        let env = StoreRepoEnv(user: .team("u1"))

        XCTAssertEqual(DriverTripsModel(backend: env.backend).uiState, .empty)
        XCTAssertTrue(DriverScheduleModel(backend: env.backend).uiState.days.isEmpty)
        XCTAssertEqual(EscortDelegationModel(backend: env.backend).uiState, .empty)
    }

    // MARK: - المرافق

    func testEscortHomeState() {
        let env = StoreRepoEnv(user: .escort("e1"))
        let state = EscortHomeState.make(env.db, escortId: "e1", today: today)
        let delegations = ResourceService.delegations(ofEscort: "e1", in: env.db)

        XCTAssertEqual(state.name, env.db.escort("e1")?.name)
        XCTAssertEqual(state.delegations.map(\.id), delegations.map(\.id))
        XCTAssertFalse(state.delegations.isEmpty)
        for card in state.delegations {
            XCTAssertTrue(card.members.allSatisfy { env.db.member($0.id)?.escortId == "e1" })
            XCTAssertEqual(card.today.map(\.time), card.today.map(\.time).sorted())
        }
        XCTAssertEqual(EscortHomeState.make(env.db, escortId: "missing", today: today), .empty)
        XCTAssertEqual(EscortDelegationModel(backend: env.backend).uiState, state)
    }

    // MARK: - التنبيهات

    func testNoticeInboxAndMarkRead() {
        let env = StoreRepoEnv(user: .member("m1"))
        let model = NoticesModel(backend: env.backend)
        let unread = env.db.unreadCount(for: .member("m1"))

        XCTAssertEqual(model.uiState.unread, unread)
        XCTAssertEqual(model.uiState.rows.count, env.db.notices(for: .member("m1")).count)
        XCTAssertTrue(model.uiState.rows.allSatisfy { !$0.text.isEmpty })

        model.markAllRead()
        XCTAssertEqual(model.uiState.unread, 0)
        XCTAssertEqual(env.db.unreadCount(for: .member("m1")), 0)
        XCTAssertEqual(NoticeInboxState.make(env.db, user: nil), .empty)
    }

    func testLiveToasterShowsOnlyNewNoticesOfTheCurrentUser() {
        let env = StoreRepoEnv(user: .member("m1"))
        let bus = MrasemToastBus()
        let toaster = LiveNoticeToaster(store: env.backend.store, toastBus: bus)
        var texts: [String] = []
        let token = bus.events.sink { texts.append($0.rest?.resolve() ?? "") }

        env.backend.store.update { _ in }
        XCTAssertTrue(texts.isEmpty, "التنبيهات القديمة مش جديدة")

        env.backend.store.update { db in
            db.notices.append(NoticeRecord(
                id: "n-live", delegationId: "d1", audience: .custom, recipients: [.member("m1")], readBy: [],
                body: .broadcast("الحافلة وصلت"), createdAt: AllRolesTestEnv.clock
            ))
        }
        XCTAssertEqual(texts, ["الحافلة وصلت"])

        env.backend.store.update { _ in }
        XCTAssertEqual(texts.count, 1, "نفس التنبيه ما يتكررش")

        env.act(as: .team("u1"))
        XCTAssertEqual(texts.count, 1, "تبديل المستخدم بيصفّر الذاكرة من غير توست")
        token.cancel()
        _ = toaster
    }

    // MARK: - الـ Shell والنصوص

    func testRoleTabs() {
        XCTAssertEqual(RoleTab.tabs(for: .driver), [.driver(.trips), .driver(.schedule)])
        XCTAssertEqual(RoleTab.tabs(for: .escort), [.escort(.delegation), .escort(.notices)])

        let env = StoreRepoEnv(user: .escort("e1"))
        let model = RoleShellModel(backend: env.backend, session: session(env.repo))
        XCTAssertEqual(model.uiState.selected, .escort(.delegation))
        model.select(.escort(.notices))
        XCTAssertEqual(model.uiState.selected, .escort(.notices))
    }

    func testNewStringKeysResolve() {
        var keys = TripStatus.allCases.flatMap { [$0.driverLabelKey, $0.driverActionKey] }
        keys += DriverTab.allCases.map(\.labelKey) + EscortTab.allCases.map(\.labelKey)
        keys += ["mrasem_live_notice_strong", "mrasem_notices_title", "mrasem_notices_mark_read", "mrasem_notices_empty",
                 "mrasem_driver_summary", "mrasem_escort_dates", "mrasem_escort_member_subtitle", "mrasem_escort_item_subtitle"]
        for key in keys {
            XCTAssertNotEqual(mrasemString(key), key, "missing string: \(key)")
        }
    }
}
