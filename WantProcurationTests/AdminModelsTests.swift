//
//  AdminModelsTests.swift
//  WantProcurationTests
//
//  Phase 14 — ViewModels الأدمن فوق الـ backend: التحديث اللحظي، الحفظ والحذف، التنقّل، وتابات الأدمن في الـ Shell.
//

import XCTest
@testable import WantProcuration

final class AdminModelsTests: XCTestCase {

    private func make(user: UserRef = .team("u1")) -> (env: StoreRepoEnv, nav: AdminNavigator, toast: MrasemToastBus) {
        (StoreRepoEnv(user: user), AdminNavigator(), MrasemToastBus())
    }

    // MARK: - الرئيسية

    func testHomeModelFollowsTheStore() {
        let (env, _, _) = make()
        let model = AdminHomeModel(backend: env.backend)
        XCTAssertEqual(model.uiState.summary.newRequests, 3)
        XCTAssertEqual(model.uiState.movements.count, 5, "تحركات ٢٤ نوفمبر")

        XCTAssertTrue(env.backend.requests.resolve("rq1"))
        XCTAssertEqual(model.uiState.summary.newRequests, 2)

        env.backend.delegations.delete("d3")
        XCTAssertEqual(model.uiState.movements.count, 4)
    }

    func testHomeModelOnEmptyApp() {
        let env = StoreRepoEnv(demo: false, user: nil)
        let model = AdminHomeModel(backend: env.backend)

        XCTAssertTrue(model.uiState.isEmpty)
        XCTAssertTrue(model.uiState.actions.isEmpty)
    }

    // MARK: - قائمة الوفود

    func testDelegationsModelFilterAndOpen() {
        let (env, nav, toast) = make()
        let model = AdminDelegationsModel(backend: env.backend, nav: nav, toastBus: toast)
        XCTAssertEqual(model.uiState.rows.map(\.id), ["d1", "d3", "d2"])

        model.onFilter(.draft)
        XCTAssertEqual(model.uiState.rows.map(\.id), ["d3"])
        XCTAssertEqual(model.uiState.filter, .draft)

        // الفلتر بيفضل بعد أي تعديل في القاعدة.
        env.backend.delegations.setStatus("d3", .active)
        XCTAssertTrue(model.uiState.rows.isEmpty)

        model.onOpen("d2")
        XCTAssertEqual(nav.openDelegationId, "d2")
    }

    func testNewDelegationDraftStartsToday() {
        let (env, nav, toast) = make()
        let draft = AdminDelegationsModel(backend: env.backend, nav: nav, toastBus: toast).newDraft()

        XCTAssertEqual(draft.start, "2026-11-24")
        XCTAssertEqual(draft.end, "2026-11-26")
        XCTAssertTrue(draft.isNew)
    }

    func testSavingNewDelegationOpensItsDetails() throws {
        let (env, nav, toast) = make()
        let model = AdminDelegationsModel(backend: env.backend, nav: nav, toastBus: toast)

        var invalid = model.newDraft()
        XCTAssertEqual(model.save(invalid), "mrasem_admin_error_name")
        XCTAssertNil(nav.openDelegationId)
        XCTAssertEqual(env.db.delegations.count, 3)

        invalid.name = "وفد من الشاشة"
        XCTAssertNil(model.save(invalid))
        let created = try XCTUnwrap(env.db.delegations.first { $0.name == "وفد من الشاشة" })
        XCTAssertEqual(nav.openDelegationId, created.id)
        XCTAssertEqual(model.uiState.counts[.all], 4)
    }

    // MARK: - تفاصيل الوفد

    private func detailModel(_ env: StoreRepoEnv, _ nav: AdminNavigator, _ toast: MrasemToastBus, id: String = "d1") -> AdminDelegationDetailModel {
        nav.open(id)
        return AdminDelegationDetailModel(backend: env.backend, delegationId: id, nav: nav, toastBus: toast)
    }

    func testDetailModelMemberCrud() {
        let (env, nav, toast) = make()
        let model = detailModel(env, nav, toast)
        XCTAssertEqual(model.uiState?.members.count, 3)

        var draft = model.memberDraft(nil)
        XCTAssertEqual(draft.delegationId, "d1")
        XCTAssertEqual(model.saveMember(draft), "mrasem_admin_error_name")

        draft.name = "عضو جديد"
        draft.room = "1300"
        XCTAssertNil(model.saveMember(draft))
        XCTAssertEqual(model.uiState?.members.count, 4)

        var edit = model.memberDraft("m3")
        edit.room = "1210"
        XCTAssertNil(model.saveMember(edit))
        XCTAssertEqual(model.uiState?.members.first { $0.id == "m3" }?.room, "1210")

        model.deleteMember("m3")
        XCTAssertEqual(model.uiState?.members.count, 3)
        XCTAssertNil(env.db.member("m3"))
    }

    func testDetailModelProgramActions() {
        let (env, nav, toast) = make()
        let model = detailModel(env, nav, toast)

        model.postpone("p4")
        XCTAssertEqual(env.db.programItem("p4")?.time, "10:00")
        XCTAssertEqual(env.db.programItem("p4")?.isChanged, true)

        var draft = model.itemDraft(nil)
        XCTAssertEqual(draft.delegationId, "d1")
        XCTAssertEqual(draft.date, "2026-11-24", "النهارده جوه فترة الوفد")
        draft.title = "فقرة جديدة"
        draft.time = "20:00"
        XCTAssertNil(model.saveItem(draft))
        XCTAssertTrue(model.uiState?.days.flatMap(\.items).contains { $0.title == "فقرة جديدة" } ?? false)

        var bad = model.itemDraft("p5")
        bad.time = "99:99"
        XCTAssertEqual(model.saveItem(bad), "mrasem_admin_error_time")

        model.deleteItem("p5")
        XCTAssertNil(env.db.programItem("p5"))
        XCTAssertEqual(model.days, ["2026-11-23", "2026-11-24", "2026-11-25"])
    }

    func testItemDraftOutsideDelegationStartsAtFirstDay() {
        let (env, nav, toast) = make()
        let model = detailModel(env, nav, toast, id: "d2")

        XCTAssertEqual(model.itemDraft(nil).date, "2026-12-07")
        XCTAssertEqual(model.itemDraft(nil, date: "2026-12-09").date, "2026-12-09")
    }

    func testDetailModelResolveAndStatus() {
        let (env, nav, toast) = make()
        let model = detailModel(env, nav, toast)

        model.resolve("rq1")
        XCTAssertEqual(model.uiState?.requests.first { $0.id == "rq1" }?.status, .done)

        model.setStatus(.archived)
        XCTAssertEqual(model.uiState?.delegation.status, .archived)
        model.setStatus(.active)
        XCTAssertEqual(model.uiState?.delegation.status, .active)
    }

    func testEditingDelegationFromTheDetailForm() throws {
        let (env, nav, toast) = make()
        let model = detailModel(env, nav, toast)

        var draft = try XCTUnwrap(model.delegationDraft())
        draft.name = "اسم معدّل"
        XCTAssertNil(model.saveDelegation(draft))
        XCTAssertEqual(model.uiState?.delegation.name, "اسم معدّل")

        draft.end = "2026-11-01"
        XCTAssertEqual(model.saveDelegation(draft), "mrasem_admin_error_range")
    }

    func testDeletingDelegationClosesTheDetail() {
        let (env, nav, toast) = make()
        let model = detailModel(env, nav, toast)
        XCTAssertEqual(nav.openDelegationId, "d1")

        model.deleteDelegation()

        XCTAssertNil(model.uiState)
        XCTAssertNil(nav.openDelegationId)
        XCTAssertNil(env.db.delegation("d1"))
        XCTAssertTrue(env.db.members.filter { $0.delegationId == "d1" }.isEmpty)
        XCTAssertTrue(env.db.program.filter { $0.delegationId == "d1" }.isEmpty)
    }

    func testEscortAndCarOptionsComeFromTheStore() {
        let (env, nav, toast) = make()
        let model = detailModel(env, nav, toast)

        XCTAssertEqual(model.escorts().count, env.db.escorts.count + 1)
        XCTAssertEqual(model.cars().count, env.db.cars.count + 1)
        XCTAssertEqual(model.hotels().first?.label, mrasemString("mrasem_admin_none"))
    }

    // MARK: - الـ Shell

    func testAdminTabsAndShellState() {
        XCTAssertEqual(RoleTab.tabs(for: .admin), [.admin(.home), .admin(.delegations), .soon(.adminResources),
                                                   .soon(.adminPlaces), .soon(.adminRequests)])

        let env = StoreRepoEnv(user: .team("u1"))
        var shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: nil)
        XCTAssertEqual(shell.selected, .admin(.home))
        XCTAssertTrue(shell.delegations.isEmpty, "الأدمن مش بيختار وفد من الهيدر")

        shell = RoleShellState.make(env.db, nav: env.repo.nav, chosen: .admin(.delegations))
        XCTAssertEqual(shell.selected, .admin(.delegations))
        XCTAssertEqual(shell.tabIndex, 1)
    }

    func testRoleShellModelSelectsAdminTabs() {
        let env = StoreRepoEnv(user: .team("u1"))
        let model = RoleShellModel(backend: env.backend, session: session(env.repo))
        XCTAssertEqual(model.uiState.selected, .admin(.home))

        model.select(.admin(.delegations))
        XCTAssertEqual(model.uiState.selected, .admin(.delegations))

        model.select(.soon(.adminRequests))
        XCTAssertEqual(model.uiState.selected, .soon(.adminRequests))
    }

    func testNavigatorOpenAndClose() {
        let nav = AdminNavigator()
        nav.open("d1")
        XCTAssertEqual(nav.openDelegationId, "d1")
        nav.close()
        XCTAssertNil(nav.openDelegationId)
    }
}
