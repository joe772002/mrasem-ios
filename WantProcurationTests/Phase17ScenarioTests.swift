//
//  Phase17ScenarioTests.swift
//  WantProcurationTests
//
//  Phase 17 — سيناريوهات نهاية-لنهاية عبر الأدوار، من تطبيق فاضي:
//  أدمن ينشئ الموارد والوفد ← يعيّن ← السائق يتحرك ويوصل ← الضيف والمرافق والمنسق يشوفوا،
//  وبعدها طلب ضيف ← إضافة للبرنامج، والحذف المتسلسل من غير عناصر يتيمة.
//

import XCTest
@testable import WantProcuration

final class Phase17ScenarioTests: XCTestCase {

    private let today = StoreRepoEnv.today.iso

    /// كل المعرّفات اللي السيناريو بيبنيها.
    private struct World {
        var hotel = "", venue = "", attraction = "", driver = "", car = "", escort = "", coordinator = ""
        var delegation = "", head = "", second = "", item = ""
    }

    /// الأدمن بيبني كل حاجة من الصفر عبر الـ services (نفس اللي الشاشات بتعمله).
    private func build(_ env: StoreRepoEnv) throws -> World {
        let b = env.backend
        var w = World()

        func place(_ kind: PlaceKind, _ name: String) throws -> String {
            var draft = PlaceDraft()
            draft.kind = kind
            draft.name = name
            draft.minutes = "10"
            return try b.resources.savePlace(draft.record()).get().id
        }
        w.hotel = try place(.hotel, "فندق الاختبار")
        w.venue = try place(.entity, "الوزارة")
        w.attraction = try place(.attraction, "المتحف")

        var driver = DriverDraft()
        driver.name = "سائق السيناريو"
        w.driver = try b.resources.saveDriver(driver.record()).get().id

        var car = CarDraft()
        car.type = "مرسيدس"
        car.plate = "12345"
        w.car = try b.resources.saveCar(car.record()).get().id
        b.resources.assignDriver(w.driver, toCar: w.car)

        var escort = EscortDraft()
        escort.name = "مرافق السيناريو"
        w.escort = try b.resources.saveEscort(escort.record()).get().id

        var coordinator = TeamUserDraft()
        coordinator.name = "منسق السيناريو"
        w.coordinator = try b.resources.saveTeamUser(coordinator.record()).get().id

        var delegation = DelegationDraft(start: today, end: StoreTime.days(from: today, to: "2026-11-25").last ?? today)
        delegation.name = "وفد السيناريو"
        delegation.hotelId = w.hotel
        delegation.venueId = w.venue
        delegation.status = .active
        var record = delegation.record()
        record.coordinatorIds = [w.coordinator]
        w.delegation = try b.delegations.save(record).get().id

        var head = MemberDraft(delegationId: w.delegation)
        head.name = "رئيس الوفد"
        head.room = "١٠١"
        head.carId = w.car
        head.escortId = w.escort
        w.head = try b.delegations.saveMember(head.record()).get().id

        var second = MemberDraft(delegationId: w.delegation)
        second.name = "عضو ثاني"
        second.carId = w.car
        w.second = try b.delegations.saveMember(second.record()).get().id

        var item = ProgramDraft(delegationId: w.delegation, date: today, notify: false)
        item.title = "اجتماع السيناريو"
        item.time = "22:00"
        item.placeId = w.venue
        item.carId = w.car
        w.item = try b.program.save(item.record(), notify: false).get().id
        return w
    }

    // MARK: - السيناريو الكامل

    func testFullJourneyFromAnEmptyApp() throws {
        let env = StoreRepoEnv(demo: false, user: nil)
        XCTAssertTrue(env.db.isEmptyOfContent)
        env.act(as: .team(MrasemSeed.defaultAdmin.id))
        XCTAssertTrue(AdminHomeBuilder.make(env.db, today: today).isEmpty)

        let w = try build(env)

        // الأدمن: الوفد جاهز من غير نواقص.
        let gaps = PortalInsights.gaps(env.db, delegationId: w.delegation)
        XCTAssertEqual([gaps.noCar, gaps.noRoom, gaps.noEscort], [0, 1, 1], "العضو التاني من غير مرافق ولا غرفة")
        XCTAssertFalse(gaps.noHotel)
        XCTAssertTrue(AdminResourcesBuilder.conflicts(env.db).isEmpty)

        // السائق يتحرك ويوصل.
        env.act(as: .driver(w.driver))
        let driverModel = DriverTripsModel(backend: env.backend)
        XCTAssertEqual(driverModel.uiState.rows.map(\.id), [w.item])
        XCTAssertEqual(driverModel.uiState.rows.first?.passengers.count, 2)
        XCTAssertEqual(driverModel.uiState.rows.first?.from, "فندق الاختبار")
        XCTAssertEqual(driverModel.uiState.rows.first?.to, "الوزارة")
        driverModel.advance(w.item)
        driverModel.advance(w.item)
        XCTAssertEqual(DriverTripService.status(of: w.item, in: env.db), .arrived)

        // الضيف: بطاقة المهمة فيها السيارة والسائق والفندق، والتنبيه «وصل».
        env.act(as: .member(w.head))
        let mission = env.state.mission
        XCTAssertEqual(mission.guest, "وفد السيناريو")
        XCTAssertEqual(mission.car.plate, "12345")
        XCTAssertEqual(mission.car.driver, "سائق السيناريو")
        XCTAssertEqual(mission.hotel.name, "فندق الاختبار")
        XCTAssertTrue(env.state.notices.contains { $0.content == .tripStatus(.arrived, driver: "سائق السيناريو") })
        XCTAssertGreaterThan(env.db.unreadCount(for: .member(w.head)), 0)

        // المرافق: وفده وعضوه وفقرة النهاردة، والتنبيه.
        env.act(as: .escort(w.escort))
        let escort = EscortHomeState.make(env.db, escortId: w.escort, today: today)
        XCTAssertEqual(escort.delegations.map(\.id), [w.delegation])
        XCTAssertEqual(escort.delegations.first?.members.map(\.id), [w.head])
        XCTAssertEqual(escort.delegations.first?.today.map(\.id), [w.item])
        XCTAssertTrue(NoticeInboxState.make(env.db, user: .escort(w.escort)).unread > 0)

        // المنسق (المستضيف): شايف الوفد ووصله التنبيه.
        env.act(as: .team(w.coordinator))
        XCTAssertEqual(ViewScope.delegations(for: .team(w.coordinator), in: env.db).map(\.id), [w.delegation])
        XCTAssertTrue(env.db.notices(for: .team(w.coordinator)).contains {
            $0.body == .tripStatus(itemId: w.item, status: .arrived)
        })

        // العضو التاني (من غير مرافق) برضه وصله التنبيه لأنه راكب.
        XCTAssertTrue(env.db.notices(for: .member(w.second)).contains {
            $0.body == .tripStatus(itemId: w.item, status: .arrived)
        })
    }

    func testGuestRequestReachesAdminAndComesBackAsProgram() throws {
        let env = StoreRepoEnv(demo: false, user: nil)
        env.act(as: .team(MrasemSeed.defaultAdmin.id))
        let w = try build(env)

        env.act(as: .member(w.second))
        XCTAssertTrue(env.backend.guest.requestVisit(memberId: w.second, placeId: w.attraction))
        XCTAssertFalse(env.backend.guest.requestVisit(memberId: w.second, placeId: w.attraction), "طلب مفتوح لنفس المكان")

        env.act(as: .team(MrasemSeed.defaultAdmin.id))
        let requests = AdminRequestsModel(backend: env.backend, toastBus: MrasemToastBus())
        let request = try XCTUnwrap(requests.uiState.items.first)
        XCTAssertEqual(request.memberName, "عضو ثاني")
        XCTAssertEqual(request.placeName, "المتحف")

        var draft = try XCTUnwrap(requests.programDraft(request.id))
        draft.time = "18:00"
        draft.carId = w.car
        XCTAssertNil(requests.addToProgram(draft))
        XCTAssertTrue(requests.uiState.items.isEmpty, "مفيش طلبات جديدة")

        XCTAssertEqual(env.backend.guest.visitRequestStatus(memberId: w.second, placeId: w.attraction), .done)
        XCTAssertTrue(env.db.notices(for: .member(w.second)).contains { $0.body == .requestResolved(requestId: request.id) })
        XCTAssertTrue(env.db.program.contains { $0.placeId == w.attraction && $0.delegationId == w.delegation })

        // السائق شايف الرحلة الجديدة في جدوله.
        XCTAssertEqual(draft.date, today, "أول يوم من النهارده")
        XCTAssertEqual(DriverTripService.trips(env.db, driverId: w.driver, on: today).map(\.item.time), ["18:00", "22:00"])
    }

    // MARK: - الحذف المتسلسل (G3)

    func testCascadingDeletesLeaveNoOrphans() throws {
        let env = StoreRepoEnv(demo: false, user: nil)
        env.act(as: .team(MrasemSeed.defaultAdmin.id))
        let w = try build(env)

        XCTAssertTrue(env.backend.resources.deleteCar(w.car))
        XCTAssertNil(env.db.member(w.head)?.carId)
        XCTAssertNil(env.db.programItem(w.item)?.carId)
        XCTAssertTrue(DriverTripService.trips(env.db, driverId: w.driver).isEmpty)

        XCTAssertTrue(env.backend.resources.deleteEscort(w.escort))
        XCTAssertNil(env.db.member(w.head)?.escortId)

        XCTAssertTrue(env.backend.resources.deletePlace(w.venue))
        XCTAssertNil(env.db.programItem(w.item)?.placeId)
        XCTAssertNil(env.db.delegation(w.delegation)?.venueId)

        // الضيف لسه بيشوف مهمة سليمة من غير سيارة.
        env.act(as: .member(w.head))
        XCTAssertEqual(env.state.mission.car.plate, "")
        XCTAssertFalse(env.state.mission.days.isEmpty)

        // حذف الوفد وهو المستخدم الحالي عضو فيه ← «اختر المستخدم».
        XCTAssertTrue(env.backend.delegations.delete(w.delegation))
        XCTAssertNil(env.db.currentUser)
        XCTAssertTrue(env.db.members.isEmpty)
        XCTAssertTrue(env.db.program.isEmpty)
        XCTAssertFalse(env.db.notices.contains { $0.recipients.isEmpty })
        XCTAssertFalse(env.db.notices.contains { $0.recipients.contains(.member(w.head)) })
        XCTAssertEqual(MrasemAppFlow.stage(env.db, confirmed: true), .pickUser)

        // المرافق اتحذف والسائق فاضل من غير رحلات.
        XCTAssertEqual(DriverHomeState.make(env.db, driverId: w.driver, today: today).rows, [])
    }

    func testWipeAllReturnsToFirstRunAndDemoReloadKeepsTheUser() throws {
        let env = StoreRepoEnv(demo: false, user: nil)
        env.act(as: .team(MrasemSeed.defaultAdmin.id))
        _ = try build(env)

        env.backend.reloadDemo()
        XCTAssertEqual(env.db.delegations.count, 3)
        XCTAssertNil(env.db.currentUser, "الأدمن الافتراضي مش في بيانات العرض")

        env.act(as: .team("u1"))
        env.backend.wipeAll()
        XCTAssertEqual(MrasemAppFlow.stage(env.db, confirmed: true), .chooseStart)
        XCTAssertTrue(env.db.isEmptyOfContent)
        XCTAssertTrue(env.db.team.contains { $0.role == .admin }, "لازم أدمن عشان الدخول")
    }
}
