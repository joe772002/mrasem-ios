//
//  Phase15ModelsTests.swift
//  WantProcurationTests
//
//  Phase 15 — ViewModels الأدمن (٢) فوق الـ backend: الموارد، الأماكن، الطلبات، والإعدادات وإدارة البيانات.
//

import XCTest
import Combine
@testable import WantProcuration

final class Phase15ModelsTests: XCTestCase {

    private func make() -> (env: StoreRepoEnv, toast: MrasemToastBus) {
        (StoreRepoEnv(user: .team("u1")), MrasemToastBus())
    }

    // MARK: - الموارد

    func testResourcesModelFollowsStoreAndSaves() {
        let (env, toast) = make()
        let model = AdminResourcesModel(backend: env.backend, toastBus: toast)
        let drivers = model.uiState.drivers.count

        XCTAssertEqual(model.save(DriverDraft()), "mrasem_admin_error_name", "اسم فاضي")
        var draft = DriverDraft()
        draft.name = "سالم"
        XCTAssertNil(model.save(draft))
        XCTAssertEqual(model.uiState.drivers.count, drivers + 1)

        model.toggleStatus("r1")
        XCTAssertEqual(model.uiState.drivers.first { $0.id == "r1" }?.status, .onLeave)
        model.toggleStatus("r1")
        XCTAssertEqual(model.uiState.drivers.first { $0.id == "r1" }?.status, .available)
    }

    func testCarSaveAssignsDriverAndDeleteClearsIt() throws {
        let (env, toast) = make()
        let model = AdminResourcesModel(backend: env.backend, toastBus: toast)

        var car = CarDraft()
        car.type = "لكزس"
        car.plate = "123"
        car.driverId = "r4"
        XCTAssertNil(model.save(car))
        let saved = try XCTUnwrap(env.db.cars.last)
        XCTAssertEqual(saved.driverId, "r4")
        XCTAssertNotNil(model.uiState.drivers.first { $0.id == "r4" }?.carLabel)

        model.deleteDriver("r4")
        XCTAssertNil(env.db.car(saved.id)?.driverId)
        XCTAssertEqual(model.driverOptions().first?.id, nil)
        XCTAssertNotNil(model.draft(car: saved.id))
        XCTAssertNil(model.draft(driver: "r4"))
    }

    func testResolveConflictMovesTheItemToAFreeCar() throws {
        let (env, toast) = make()
        let model = AdminResourcesModel(backend: env.backend, toastBus: toast)
        let conflict = try XCTUnwrap(model.uiState.conflicts.first)
        let itemId = conflict.second.itemId

        let driver = try env.backend.resources.saveDriver(DriverRecord(id: "", name: "بديل", phone: "", status: .available)).get()
        let car = try env.backend.resources.saveCar(CarRecord(id: "", type: "ن", plate: "9", plateStyle: .qatar, driverId: driver.id)).get()

        XCTAssertTrue(model.alternatives(forItem: itemId).contains { $0.id == car.id })
        XCTAssertTrue(model.resolve(itemId: itemId, carId: car.id))
        XCTAssertEqual(env.db.programItem(itemId)?.carId, car.id)
        XCTAssertFalse(model.uiState.conflicts.contains { $0.id == conflict.id })
        XCTAssertFalse(model.resolve(itemId: "missing", carId: car.id))
    }

    // MARK: - الأماكن

    func testPlacesModelFilterSaveDelete() {
        let (env, toast) = make()
        let model = AdminPlacesModel(backend: env.backend, toastBus: toast)
        let all = model.uiState.rows.count

        model.onFilter(.hotel)
        XCTAssertTrue(model.uiState.rows.allSatisfy { $0.kind == .hotel })
        XCTAssertEqual(model.newDraft().kind, .hotel, "الفلتر بيحدد نوع المكان الجديد")

        var draft = model.newDraft()
        XCTAssertEqual(model.save(draft), "mrasem_admin_error_name")
        draft.name = "فندق جديد"
        draft.minutes = "x"
        XCTAssertEqual(model.save(draft), "mrasem_admin_error_time")
        draft.minutes = "15"
        XCTAssertNil(model.save(draft))

        model.onFilter(.all)
        XCTAssertEqual(model.uiState.rows.count, all + 1)

        let id = env.db.places.last?.id ?? ""
        model.delete(id)
        XCTAssertEqual(model.uiState.rows.count, all)
        XCTAssertNil(model.draft(place: id))
    }

    // MARK: - الطلبات

    func testRequestsModelResolveAndReply() {
        let (env, toast) = make()
        let model = AdminRequestsModel(backend: env.backend, toastBus: toast)
        XCTAssertEqual(model.uiState.items.count, 3)

        model.resolve("rq1")
        XCTAssertEqual(model.uiState.items.count, 2, "الفلتر «جديد»")

        XCTAssertEqual(model.reply(RequestReplyDraft(requestId: "rq2", text: "  ")), "mrasem_admin_error_reply")
        XCTAssertNil(model.reply(RequestReplyDraft(requestId: "rq2", text: "تم الحجز")))
        XCTAssertEqual(env.db.requests.first { $0.id == "rq2" }?.status, .done)
        XCTAssertEqual(env.db.requests.first { $0.id == "rq2" }?.reply, "تم الحجز")

        model.onFilter(.done)
        XCTAssertTrue(model.uiState.items.allSatisfy { $0.status == .done })
        XCTAssertEqual(model.replyDraft("rq2").text, "تم الحجز")
    }

    func testRequestToProgram() throws {
        let (env, toast) = make()
        let model = AdminRequestsModel(backend: env.backend, toastBus: toast)
        let before = env.db.program.count

        var draft = try XCTUnwrap(model.programDraft("rq1"))
        XCTAssertTrue(model.programDays("rq1").contains(draft.date))
        XCTAssertNil(model.programDraft("missing"))

        draft.time = "99:99"
        XCTAssertEqual(model.addToProgram(draft), "mrasem_admin_error_time")

        draft.time = "10:00"
        XCTAssertNil(model.addToProgram(draft))
        XCTAssertEqual(env.db.program.count, before + 1)
        XCTAssertEqual(env.db.requests.first { $0.id == "rq1" }?.status, .done)
    }

    func testBroadcastFlow() throws {
        let (env, toast) = make()
        let model = AdminRequestsModel(backend: env.backend, toastBus: toast)
        var draft = try XCTUnwrap(model.broadcastDraft())
        let baseline = model.uiState.broadcasts.count

        XCTAssertEqual(model.send(draft), "mrasem_admin_error_broadcast", "نص فاضي")
        draft.text = "الحافلة تتحرك ٩ صباحاً"
        draft.audience = .all
        XCTAssertNil(model.send(draft))
        XCTAssertEqual(model.uiState.broadcasts.count, baseline + 1)
        XCTAssertEqual(model.uiState.broadcasts.first { $0.text == "الحافلة تتحرك ٩ صباحاً" }?.audience, .all)
        XCTAssertEqual(model.delegationOptions().count, env.db.delegations.count)
    }

    func testBroadcastDraftIsNilWithoutDelegations() {
        let env = StoreRepoEnv(demo: false, user: nil)
        let model = AdminRequestsModel(backend: env.backend, toastBus: MrasemToastBus())

        XCTAssertNil(model.broadcastDraft())
        XCTAssertFalse(model.uiState.hasDelegations)
    }

    // MARK: - الإعدادات

    func testSettingsPreferences() {
        let (env, toast) = make()
        let model = AdminSettingsModel(backend: env.backend, toastBus: toast)

        model.set(\.notifyDaily, true)
        XCTAssertTrue(env.db.preferences.notifyDaily)
        XCTAssertTrue(model.uiState.preferences.notifyDaily)
        model.set(\.autoNotifyGuests, false)
        XCTAssertFalse(model.uiState.preferences.autoNotifyGuests)

        model.set(theme: .dark)
        model.set(defaultMode: .outbound)
        XCTAssertEqual(model.uiState.preferences.theme, .dark)
        XCTAssertEqual(model.uiState.preferences.defaultMode, .outbound)
        XCTAssertEqual(model.newDestination().mode, .outbound)
    }

    func testTeamRulesProtectLastAdmin() {
        let (env, toast) = make()
        let model = AdminSettingsModel(backend: env.backend, toastBus: toast)
        var events = 0
        let token = toast.events.sink { _ in events += 1 }

        var admin = model.draft(team: "u1") ?? TeamUserDraft()
        admin.role = .viewer
        XCTAssertEqual(model.save(admin), "mrasem_admin_error_last_admin")

        model.deleteTeam("u1")
        XCTAssertNotNil(env.db.teamUser("u1"), "آخر أدمن ما بيتحذفش")
        XCTAssertEqual(events, 1, "توست بالسبب")

        var user = TeamUserDraft()
        user.name = "منسق جديد"
        XCTAssertNil(model.save(user))
        XCTAssertEqual(model.uiState.team.count, 3)

        admin.role = .admin
        admin.name = "أدمن بعد التعديل"
        XCTAssertNil(model.save(admin))
        token.cancel()
    }

    func testDestinationEditing() throws {
        let (env, toast) = make()
        let model = AdminSettingsModel(backend: env.backend, toastBus: toast)
        let id = try XCTUnwrap(env.db.destinations.first?.id)

        var draft = try XCTUnwrap(model.draft(destination: id))
        draft.name = ""
        XCTAssertEqual(model.save(draft), "mrasem_admin_error_name")
        draft.name = "وجهة محدّثة"
        XCTAssertNil(model.save(draft))
        XCTAssertEqual(env.db.destination(id)?.name, "وجهة محدّثة")

        model.deleteDestination(id)
        XCTAssertNil(env.db.destination(id))
        XCTAssertEqual(model.uiState.destinations.count, env.db.destinations.count)
    }

    func testDataManagement() {
        let (env, toast) = make()
        let model = AdminSettingsModel(backend: env.backend, toastBus: toast)

        XCTAssertTrue(model.deleteDelegation("d3"))
        XCTAssertFalse(model.deleteDelegation("d3"))
        XCTAssertEqual(model.uiState.counts.delegations, 2)

        model.reloadDemo()
        XCTAssertEqual(env.db.delegations.count, 3, "بيانات العرض رجعت")
        XCTAssertEqual(env.db.currentUser, .team("u1"), "المستخدم الحالي فضل")

        model.wipeAll()
        XCTAssertFalse(env.db.didChooseStart, "رجع لأول تشغيل")
        XCTAssertTrue(env.db.delegations.isEmpty)
        XCTAssertEqual(MrasemAppFlow.stage(env.db, confirmed: true), .chooseStart)
    }

    // MARK: - الـ Shell

    func testAdminShellHasFiveTabs() {
        XCTAssertEqual(AdminTab.allCases, [.home, .delegations, .resources, .places, .requests])
        XCTAssertEqual(RoleTab.tabs(for: .admin).count, 5)
        XCTAssertTrue(RoleTab.tabs(for: .admin).allSatisfy { if case .admin = $0 { return true } else { return false } })
    }
}
