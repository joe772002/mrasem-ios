//
//  Phase15LogicTests.swift
//  WantProcurationTests
//
//  Phase 15 — منطق الأدمن (٢): الموارد والتعارضات، الأماكن، الطلبات والتنبيهات، الإعدادات، والمسوّدات.
//

import XCTest
@testable import WantProcuration

final class Phase15LogicTests: XCTestCase {

    private let today = "2026-11-24"

    // MARK: - الموارد

    func testDriverRowsShowCarAndStatus() {
        let db = StoreRepoEnv(user: .team("u1")).db
        let rows = AdminResourcesBuilder.drivers(db, today: today)

        XCTAssertEqual(rows.count, db.drivers.count)
        XCTAssertEqual(rows.first { $0.id == "r4" }?.status, .onLeave)
        XCTAssertNotNil(rows.first { $0.id == "r1" }?.carLabel)
    }

    func testCarAndEscortRows() {
        let db = StoreRepoEnv(user: .team("u1")).db

        XCTAssertEqual(AdminResourcesBuilder.cars(db).count, db.cars.count)
        XCTAssertEqual(AdminResourcesBuilder.cars(db).first { $0.id == "c1" }?.driverName, db.driver("r1")?.name)
        XCTAssertEqual(AdminResourcesBuilder.escorts(db).count, db.escorts.count)
    }

    func testConflictRowsMatchInsights() {
        let db = StoreRepoEnv(user: .team("u1")).db
        let rows = AdminResourcesBuilder.conflicts(db)

        XCTAssertEqual(rows.count, PortalInsights.conflicts(db).count)
        XCTAssertFalse(rows.isEmpty)
        XCTAssertEqual(Set(rows.flatMap { [$0.first.itemId, $0.second.itemId] }), PortalInsights.conflictItemIds(db))
        XCTAssertEqual(rows.first?.driverName, db.driver("r1")?.name)
    }

    func testAssignmentsAreUpcomingSortedAndFlagged() {
        let db = StoreRepoEnv(user: .team("u1")).db
        let rows = AdminResourcesBuilder.assignments(db, today: today)
        let conflicts = PortalInsights.conflictItemIds(db)

        XCTAssertTrue(rows.allSatisfy { $0.date >= today })
        XCTAssertEqual(rows.map { $0.date + $0.time }, rows.map { $0.date + $0.time }.sorted())
        XCTAssertTrue(rows.allSatisfy { $0.hasConflict == conflicts.contains($0.id) })
    }

    func testAlternativesSkipBusyAndUnavailableDrivers() throws {
        let env = StoreRepoEnv(user: .team("u1"))
        let itemId = try XCTUnwrap(AdminResourcesBuilder.conflicts(env.db).first?.second.itemId)
        let item = try XCTUnwrap(env.db.programItem(itemId))

        let before = AdminResourcesBuilder.alternatives(env.db, forItem: itemId)
        XCTAssertFalse(before.contains { $0.id == item.carId })
        XCTAssertTrue(before.allSatisfy { env.db.driver($0.driverId)?.status == .available })

        let driver = try env.backend.resources.saveDriver(DriverRecord(id: "", name: "سائق جديد", phone: "1", status: .available)).get()
        let car = try env.backend.resources.saveCar(CarRecord(id: "", type: "ن", plate: "1", plateStyle: .qatar, driverId: driver.id)).get()

        XCTAssertTrue(AdminResourcesBuilder.alternatives(env.db, forItem: itemId).contains { $0.id == car.id })
        XCTAssertTrue(AdminResourcesBuilder.alternatives(env.db, forItem: "missing").isEmpty)

        env.backend.resources.setDriverStatus(driver.id, .onLeave)
        XCTAssertFalse(AdminResourcesBuilder.alternatives(env.db, forItem: itemId).contains { $0.id == car.id })
    }

    // MARK: - الأماكن

    func testPlacesFilterCountsAndUsage() {
        let db = StoreRepoEnv(user: .team("u1")).db

        XCTAssertEqual(AdminPlacesBuilder.rows(db, filter: .all).count, db.places.count)
        XCTAssertTrue(AdminPlacesBuilder.rows(db, filter: .hotel).allSatisfy { $0.kind == .hotel })
        XCTAssertEqual(AdminPlacesBuilder.counts(db)[.all], db.places.count)
        XCTAssertEqual(PlaceFilter.hotel.kind, .hotel)
        XCTAssertNil(PlaceFilter.all.kind)
        XCTAssertGreaterThanOrEqual(AdminPlacesBuilder.usage(of: "h1", in: db), 1, "الفندق h1 عليه وفد")
    }

    // MARK: - الطلبات

    func testRequestFiltersAndCounts() {
        let db = StoreRepoEnv(user: .team("u1")).db
        let counts = AdminRequestsBuilder.counts(db)

        XCTAssertEqual(counts[.new], 3)
        XCTAssertEqual(counts[.done], 1)
        XCTAssertEqual(counts[.all], 4)

        let items = AdminRequestsBuilder.items(db, filter: .new)
        XCTAssertEqual(items.count, 3)
        XCTAssertTrue(items.allSatisfy { $0.status == .new })
        XCTAssertEqual(items.map(\.createdAt), items.map(\.createdAt).sorted(by: >), "الأحدث الأول")
        XCTAssertFalse(items.contains { $0.delegationName.isEmpty })
    }

    func testBroadcastHistory() {
        let env = StoreRepoEnv(user: .team("u1"))
        let baseline = AdminRequestsBuilder.broadcasts(env.db).count

        XCTAssertTrue(env.backend.requests.broadcast("الاجتماع الساعة ١٠", delegationId: "d1", audience: .all))
        XCTAssertFalse(env.backend.requests.broadcast("x", delegationId: "d1", audience: .custom))

        let rows = AdminRequestsBuilder.broadcasts(env.db)
        XCTAssertEqual(rows.count, baseline + 1)
        let row = rows.first { $0.text == "الاجتماع الساعة ١٠" }
        XCTAssertEqual(row?.audience, .all)
        XCTAssertGreaterThan(row?.recipientCount ?? 0, 0)
        XCTAssertEqual(row?.readCount, 0)
        XCTAssertEqual(NoticeAudience.broadcastChoices, [.all, .escorts, .drivers])
    }

    // MARK: - الإعدادات

    func testSettingsState() {
        let db = StoreRepoEnv(user: .team("u1")).db
        let state = AdminSettingsState.make(db)

        XCTAssertEqual(state.team.count, db.team.count)
        XCTAssertEqual(state.team.first { $0.id == "u2" }?.delegationCount, 2)
        XCTAssertEqual(state.counts.delegations, 3)
        XCTAssertEqual(state.counts.members, db.members.count)
        XCTAssertEqual(state.delegations.compactMap(\.id), db.delegations.map(\.id))
        XCTAssertEqual(state.destinations.count, db.destinations.count)
        XCTAssertEqual(state.preferences, db.preferences)
    }

    func testThemeChoiceMapping() {
        XCTAssertEqual(ThemeChoice.light.option, .light)
        XCTAssertEqual(ThemeChoice.dark.option, .dark)
        XCTAssertEqual(ThemeChoice.system.option, .system)
        XCTAssertEqual(ThemeChoice.light.colorScheme, .light)
        XCTAssertEqual(ThemeChoice.dark.colorScheme, .dark)
        XCTAssertNil(ThemeChoice.system.colorScheme)
    }

    // MARK: - المسوّدات

    func testResourceDraftsRoundTrip() {
        let db = StoreRepoEnv(user: .team("u1")).db

        for record in db.drivers { XCTAssertEqual(DriverDraft(record).record(), record) }
        for record in db.cars { XCTAssertEqual(CarDraft(record).record(), record) }
        for record in db.escorts { XCTAssertEqual(EscortDraft(record).record(), record) }
        for record in db.team { XCTAssertEqual(TeamUserDraft(record).record(), record) }
        for record in db.places { XCTAssertEqual(PlaceDraft(record).record(), record, record.id) }

        XCTAssertTrue(DriverDraft().isNew)
        XCTAssertFalse(DriverDraft(db.drivers[0]).isNew)
        XCTAssertTrue(PlaceDraft().isNew)
        XCTAssertTrue(TeamUserDraft().isNew)
    }

    func testPlaceDraftKeepsHiddenFieldsAndFlagsBadNumbers() throws {
        let env = StoreRepoEnv(user: .team("u1"))
        var place = try XCTUnwrap(env.db.places.first)
        place.latitude = 25.3
        place.longitude = 51.5
        XCTAssertNotNil(try? env.backend.resources.savePlace(place).get())

        var draft = PlaceDraft(try XCTUnwrap(env.db.place(place.id)))
        draft.name = "اسم جديد"
        XCTAssertEqual(draft.record().latitude, 25.3)
        XCTAssertEqual(draft.record().longitude, 51.5)

        draft.minutes = "abc"
        XCTAssertEqual(draft.record().minutes, -1)
        XCTAssertEqual(env.backend.resources.savePlace(draft.record()), .failure(.invalidTime))

        draft.minutes = ""
        XCTAssertEqual(draft.record().minutes, 0)
        draft.durationHours = "1.5"
        XCTAssertEqual(draft.record().durationHours, 1.5)
    }

    func testDestinationDraftParsesLinesAndKeepsTheRest() throws {
        XCTAssertEqual(DestinationDraft.lines("  أ \n\n ب "), ["أ", "ب"])
        XCTAssertEqual(DestinationDraft.pairs("الشرطة: 999\nبدون قيمة"),
                       [LabelValueRecord(label: "الشرطة", value: "999"), LabelValueRecord(label: "بدون قيمة", value: "")])

        let db = StoreRepoEnv(user: .team("u1")).db
        let record = try XCTUnwrap(db.destinations.first)
        var draft = DestinationDraft(record)
        XCTAssertEqual(draft.record(), record, "من غير تعديل السجل ما يتغيرش")

        draft.name = "وجهة معدّلة"
        draft.customs = "بند ١\nبند ٢"
        let edited = draft.record()
        XCTAssertEqual(edited.name, "وجهة معدّلة")
        XCTAssertEqual(edited.customs, ["بند ١", "بند ٢"])
        XCTAssertEqual(edited.services, record.services)
        XCTAssertEqual(edited.dressSets, record.dressSets)
        XCTAssertTrue(DestinationDraft().isNew)
    }

    func testRequestDrafts() {
        var program = RequestProgramDraft(requestId: "rq1", date: "2026-11-24")
        XCTAssertEqual(program.id, "rq1")
        program.time = "11:30"
        XCTAssertEqual(program.time, "11:30")
        XCTAssertEqual(RequestReplyDraft(requestId: "rq2").text, "")
        XCTAssertEqual(BroadcastDraft(delegationId: "d1").audience, .all)
    }

    // MARK: - النصوص

    func testNewStringKeysResolve() {
        var keys: [String] = []
        keys += ResourceSection.allCases.map(\.titleKey) + AdminTab.allCases.map(\.labelKey)
        keys += RequestFilter.allCases.map(\.titleKey) + PlaceFilter.allCases.map(\.titleKey)
        keys += PlaceKind.allCases.map(\.adminLabelKey) + TeamRole.allCases.map(\.adminLabelKey)
        keys += ThemeChoice.allCases.map(\.adminLabelKey) + DriverStatus.allCases.map(\.adminLabelKey)
        keys += PlateStyle.allCases.map(\.adminLabelKey) + NoticeAudience.allCases.map(\.adminLabelKey)
        keys += ["mrasem_header_settings", "mrasem_admin_settings_title", "mrasem_admin_data_wipe_all",
                 "mrasem_admin_error_reply", "mrasem_admin_error_broadcast", "mrasem_admin_toast_error_strong"]
        for key in keys {
            XCTAssertNotEqual(mrasemString(key), key, "missing string: \(key)")
        }
    }
}
