//
//  Phase17ValidationTests.swift
//  WantProcurationTests
//
//  Phase 17 — التحقق من المدخلات (مراجع محذوفة، تقليص أيام الوفد، أرقام وأوقات غلط)
//  والحالات الفاضية لكل شاشة على تطبيق فاضي (G5).
//

import XCTest
@testable import WantProcuration

final class Phase17ValidationTests: XCTestCase {

    private let today = StoreRepoEnv.today.iso

    // MARK: - التحقق

    func testShrinkingDelegationDaysWithProgramIsRejected() throws {
        let env = StoreRepoEnv(user: .team("u1"))
        var d1 = try XCTUnwrap(env.db.delegation("d1"))
        d1.end = "2026-11-24"
        XCTAssertEqual(env.backend.delegations.save(d1), .failure(.programOutsideRange), "فقرات ٢٥ نوفمبر")
        XCTAssertEqual(StoreValidationError.programOutsideRange.messageKey, "mrasem_admin_error_program_outside")

        d1.end = "2026-11-26"
        XCTAssertNotNil(try? env.backend.delegations.save(d1).get(), "التمديد مسموح")
    }

    func testDanglingReferencesAreRejected() throws {
        let env = StoreRepoEnv(user: .team("u1"))

        var member = try XCTUnwrap(env.db.member("m1"))
        member.carId = "deleted-car"
        XCTAssertEqual(env.backend.delegations.saveMember(member), .failure(.notFound))
        member.carId = nil
        member.escortId = "deleted-escort"
        XCTAssertEqual(env.backend.delegations.saveMember(member), .failure(.notFound))

        var item = try XCTUnwrap(env.db.programItem("p4"))
        item.carId = "deleted-car"
        XCTAssertEqual(env.backend.program.save(item), .failure(.notFound))
        item.carId = nil
        item.placeId = "deleted-place"
        XCTAssertEqual(env.backend.program.save(item), .failure(.notFound))
    }

    func testFormInputErrors() {
        let env = StoreRepoEnv(user: .team("u1"))
        let res = AdminResourcesModel(backend: env.backend, toastBus: MrasemToastBus())
        let places = AdminPlacesModel(backend: env.backend, toastBus: MrasemToastBus())
        let requests = AdminRequestsModel(backend: env.backend, toastBus: MrasemToastBus())

        XCTAssertEqual(res.save(CarDraft()), "mrasem_admin_error_name")
        XCTAssertEqual(res.save(EscortDraft()), "mrasem_admin_error_name")

        var place = PlaceDraft()
        place.name = "مكان"
        place.durationHours = "ساعة"
        XCTAssertEqual(places.save(place), "mrasem_admin_error_time")

        var draft = RequestProgramDraft(requestId: "rq1", date: "2026-12-30")
        XCTAssertEqual(requests.addToProgram(draft), "mrasem_admin_error_outside")
        draft.date = today
        draft.time = "٢٥:٠٠"  // بعد التحويل «25:00» = وقت غلط
        XCTAssertEqual(requests.addToProgram(draft), "mrasem_admin_error_time")

        var dest = DestinationDraft()
        dest.name = "  "
        XCTAssertEqual(AdminSettingsModel(backend: env.backend, toastBus: MrasemToastBus()).save(dest), "mrasem_admin_error_name")
    }

    func testArabicDigitsAreAcceptedInDatesTimesAndNumbers() throws {
        XCTAssertEqual(" ١٠:٣٠ ".storeLatinDigits, "10:30")
        XCTAssertEqual("۲۰۲۶-۱۱-۲۴".storeLatinDigits, "2026-11-24")
        XCTAssertEqual("١٫٥".storeLatinDigits, "1.5")
        XCTAssertEqual("سوق 12".storeLatinDigits, "سوق 12")

        let env = StoreRepoEnv(user: .team("u1"))
        var item = ProgramDraft(delegationId: "d1", date: today, notify: false)
        item.title = "فقرة"
        item.time = "١٠:٣٠"
        let saved = try env.backend.program.save(item.record(), notify: false).get()
        XCTAssertEqual(saved.time, "10:30")

        var delegation = DelegationDraft(start: "٢٠٢٦-١١-٢٤", end: "٢٠٢٦-١١-٢٥")
        delegation.name = "وفد"
        XCTAssertEqual(try env.backend.delegations.save(delegation.record()).get().start, "2026-11-24")

        var place = PlaceDraft()
        place.minutes = "١٥"
        place.durationHours = "١٫٥"
        XCTAssertEqual(place.record().minutes, 15)
        XCTAssertEqual(place.record().durationHours, 1.5)

        var request = RequestProgramDraft(requestId: "rq1", date: today)
        request.time = "٢٠:٠٠"
        XCTAssertNil(AdminRequestsModel(backend: env.backend, toastBus: MrasemToastBus()).addToProgram(request))
        XCTAssertTrue(env.db.program.contains { $0.time == "20:00" && $0.date == today })
    }

    func testEveryValidationErrorHasAString() {
        let all: [StoreValidationError] = [.emptyName, .invalidDate, .invalidTime, .endBeforeStart,
                                           .dateOutsideDelegation, .notFound, .lastAdmin, .programOutsideRange]
        for error in all {
            XCTAssertNotEqual(mrasemString(error.messageKey), error.messageKey, "\(error)")
        }
    }

    // MARK: - الحالات الفاضية (G5)

    func testEveryAdminStateBuildsOnAnEmptyApp() {
        let db = StoreRepoEnv(demo: false, user: nil).db

        XCTAssertTrue(AdminHomeBuilder.make(db, today: today).isEmpty)
        XCTAssertTrue(AdminDelegationList.rows(db, filter: .all).isEmpty)
        XCTAssertNil(AdminDelegationDetailBuilder.make(db, id: "missing"))
        let resources = AdminResourcesState.make(db, today: today)
        XCTAssertTrue(resources.drivers.isEmpty && resources.cars.isEmpty && resources.escorts.isEmpty)
        XCTAssertTrue(resources.assignments.isEmpty && resources.conflicts.isEmpty)
        XCTAssertTrue(AdminPlacesState.make(db, filter: .all).rows.isEmpty)
        let requests = AdminRequestsState.make(db, filter: .all)
        XCTAssertTrue(requests.items.isEmpty && requests.broadcasts.isEmpty)
        XCTAssertFalse(requests.hasDelegations)
        let settings = AdminSettingsState.make(db)
        XCTAssertEqual(settings.team.count, 1, "الأدمن الافتراضي بس")
        XCTAssertTrue(settings.destinations.isEmpty && settings.delegations.isEmpty)
    }

    func testRoleScreensOnEmptyData() {
        let env = StoreRepoEnv(demo: false, user: nil)
        let b = env.backend

        let driver = try? b.resources.saveDriver(DriverRecord(id: "", name: "سائق", phone: "", status: .available)).get()
        let escort = try? b.resources.saveEscort(EscortRecord(id: "", name: "مرافق", title: "", phone: "", meetingSpot: "")).get()
        let driverId = driver?.id ?? ""
        let escortId = escort?.id ?? ""

        env.act(as: .driver(driverId))
        let trips = DriverTripsModel(backend: b)
        XCTAssertTrue(trips.uiState.rows.isEmpty)
        XCTAssertNil(trips.uiState.carLabel)
        XCTAssertTrue(DriverScheduleModel(backend: b).uiState.days.isEmpty)
        XCTAssertTrue(trips.notices.rows.isEmpty)

        env.act(as: .escort(escortId))
        XCTAssertTrue(EscortDelegationModel(backend: b).uiState.delegations.isEmpty)
        XCTAssertEqual(NoticesModel(backend: b).uiState, .empty)

        // المرافق ملوش وفد: الـ Shell مش محتاج وفد للمرافق.
        let shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: nil)
        XCTAssertEqual(shell.selected, .escort(.delegation))
        XCTAssertFalse(shell.needsDelegation)
    }

    func testGuestAndCoordinatorWithoutDelegation() {
        let env = StoreRepoEnv(demo: false, user: nil)
        let coordinator = try? env.backend.resources.saveTeamUser(
            TeamUserRecord(id: "", name: "منسق", role: .coordinator, phone: "", email: "")
        ).get()

        env.act(as: .team(coordinator?.id ?? ""))
        let shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: nil)
        XCTAssertTrue(shell.needsDelegation)
        XCTAssertFalse(shell.hasDelegation, "رسالة «لا يوجد وفد» بدل شاشة فاضية")
        XCTAssertFalse(env.state.mission.days.isEmpty, "المهمة الفاضية فيها يوم واحد على الأقل")
    }

    func testMissionFallbackNeverCrashes() {
        var state = MrasemState(missions: [:])
        state.mode = .outbound
        XCTAssertEqual(state.mission.mode, .outbound)
        XCTAssertEqual(state.mission.guest, "")
    }

    func testNewStringKeysResolve() {
        for key in ["mrasem_admin_error_program_outside"] {
            XCTAssertNotEqual(mrasemString(key), key, "missing string: \(key)")
        }
    }
}
