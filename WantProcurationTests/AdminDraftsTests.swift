//
//  AdminDraftsTests.swift
//  WantProcurationTests
//
//  Phase 14 — مسوّدات النماذج: بتحافظ على الحقول اللي مش في النموذج، وبتتحقق عن طريق الـ services، ومفاتيح الأخطاء والنصوص.
//

import XCTest
@testable import WantProcuration

final class AdminDraftsTests: XCTestCase {

    // MARK: - الوفد

    func testDelegationDraftRoundTripKeepsHiddenFields() throws {
        let env = AllRolesTestEnv()
        let original = try XCTUnwrap(env.db.delegation("d1"))

        XCTAssertEqual(DelegationDraft(original).record(), original, "المنسقون والوجهة وبطاقة اللقاء ما بتتغيرش")
        XCTAssertFalse(DelegationDraft(original).isNew)
    }

    func testCreatingDelegationFromNewDraft() throws {
        let env = AllRolesTestEnv(demo: false)
        var draft = DelegationDraft(start: "2026-11-24", end: "2026-11-26")
        XCTAssertTrue(draft.isNew)

        draft.name = "  وفد جديد  "
        draft.host = " الجهة "
        let saved = try env.delegations.save(draft.record()).get()

        XCTAssertFalse(saved.id.isEmpty)
        XCTAssertEqual(saved.name, "وفد جديد")
        XCTAssertEqual(saved.host, "الجهة")
        XCTAssertEqual(saved.status, .draft)
        XCTAssertEqual(env.db.delegations.map(\.id), [saved.id])
    }

    func testEditingDelegationThroughDraft() throws {
        let env = AllRolesTestEnv()
        var draft = DelegationDraft(try XCTUnwrap(env.db.delegation("d1")))
        draft.name = "اسم جديد"
        draft.status = .archived
        draft.hotelId = nil

        _ = try env.delegations.save(draft.record()).get()

        let saved = try XCTUnwrap(env.db.delegation("d1"))
        XCTAssertEqual(saved.name, "اسم جديد")
        XCTAssertEqual(saved.status, .archived)
        XCTAssertNil(saved.hotelId)
        XCTAssertEqual(saved.coordinatorIds, ["u2"])
        XCTAssertEqual(env.db.delegations.count, 3, "تعديل مش إضافة")
    }

    func testDelegationValidationErrorsHaveMessages() {
        let env = AllRolesTestEnv(demo: false)

        var draft = DelegationDraft(start: "2026-11-24", end: "2026-11-26")
        XCTAssertEqual(failure(env.delegations.save(draft.record())), .emptyName)

        draft.name = "وفد"
        draft.start = "غلط"
        XCTAssertEqual(failure(env.delegations.save(draft.record())), .invalidDate)

        draft.start = "2026-11-27"
        XCTAssertEqual(failure(env.delegations.save(draft.record())), .endBeforeStart)
        XCTAssertTrue(env.db.delegations.isEmpty, "مفيش حاجة اتحفظت")
    }

    // MARK: - العضو

    func testMemberDraftRoundTrip() throws {
        let env = AllRolesTestEnv()
        for id in ["m1", "m3"] {
            let original = try XCTUnwrap(env.db.member(id))
            XCTAssertEqual(MemberDraft(original).record(), original)
        }
    }

    func testFirstMemberOfNewDelegationBecomesHead() throws {
        let env = AllRolesTestEnv(demo: false)
        var delegation = DelegationDraft(start: "2026-11-24", end: "2026-11-25")
        delegation.name = "وفد"
        let saved = try env.delegations.save(delegation.record()).get()

        var member = MemberDraft(delegationId: saved.id)
        XCTAssertTrue(member.isNew)
        member.name = "عضو"
        let first = try env.delegations.saveMember(member.record()).get()

        XCTAssertTrue(first.isHead)
        XCTAssertEqual(first.appStatus, .invited)
    }

    func testChangingCarThroughDraftNotifiesMemberAndDrivers() throws {
        let env = AllRolesTestEnv()
        env.act(as: .team("u1"))

        var draft = MemberDraft(try XCTUnwrap(env.db.member("m2")))
        draft.carId = "c2"
        _ = try env.delegations.saveMember(draft.record()).get()

        XCTAssertEqual(env.lastNotice(for: .member("m2")), .assignmentChanged(memberId: "m2"))
        XCTAssertTrue(env.lastRecipients.isSuperset(of: [.member("m2"), .driver("r1"), .driver("r2")]))
    }

    func testMemberWithoutNameIsRejected() {
        let env = AllRolesTestEnv()
        XCTAssertEqual(failure(env.delegations.saveMember(MemberDraft(delegationId: "d1").record())), .emptyName)
    }

    // MARK: - الفقرة

    func testProgramDraftRoundTrip() throws {
        let env = AllRolesTestEnv()
        for id in ["p4", "p1", "q6"] {
            let original = try XCTUnwrap(env.db.programItem(id))
            XCTAssertEqual(ProgramDraft(original).record(), original, id)
        }
    }

    func testProgramDraftValidation() throws {
        let env = AllRolesTestEnv()

        var draft = ProgramDraft(delegationId: "d1", date: "2026-12-30")
        draft.title = "فقرة"
        XCTAssertEqual(failure(env.program.save(draft.record(), notify: false)), .dateOutsideDelegation)

        draft.date = "2026-11-24"
        draft.kind = .free
        draft.time = "10:00"
        draft.endTime = "09:00"
        XCTAssertEqual(failure(env.program.save(draft.record(), notify: false)), .endBeforeStart)

        draft.kind = .meal
        draft.time = "25:99"
        XCTAssertEqual(failure(env.program.save(draft.record(), notify: false)), .invalidTime)
    }

    func testNewProgramItemAppearsInDetail() throws {
        let env = AllRolesTestEnv()
        var draft = ProgramDraft(delegationId: "d1", date: "2026-11-25")
        draft.title = "لقاء إضافي"
        draft.time = "18:00"
        let saved = try env.program.save(draft.record(), notify: draft.notify).get()

        let detail = try XCTUnwrap(AdminDelegationDetailBuilder.make(env.db, id: "d1"))
        XCTAssertTrue(detail.days.last?.items.contains { $0.id == saved.id } ?? false)
    }

    // MARK: - الاختيارات والنصوص

    func testOptionsStartWithNone() {
        let db = MrasemSeed.demo()
        let hotels = AdminOptions.hotels(db, none: "بدون")
        XCTAssertNil(hotels[0].id)
        XCTAssertEqual(hotels[0].label, "بدون")
        XCTAssertEqual(hotels.dropFirst().compactMap(\.id), db.places.filter { $0.kind == .hotel }.map(\.id))
        XCTAssertFalse(AdminOptions.venues(db, none: "").contains { $0.id == "h1" })
        XCTAssertEqual(AdminOptions.cars(db, none: "").count, db.cars.count + 1)
        XCTAssertEqual(AdminOptions.escorts(db, none: "").count, db.escorts.count + 1)
        XCTAssertEqual(AdminOptions.places(db, none: "").count, db.places.count + 1)
    }

    func testAdminStringKeysResolve() {
        var keys = ["mrasem_admin_home_title", "mrasem_admin_home_date", "mrasem_admin_actions_empty", "mrasem_admin_movements_empty",
                    "mrasem_admin_delegations_add", "mrasem_admin_filter_count", "mrasem_admin_delegation_subtitle",
                    "mrasem_admin_readiness", "mrasem_admin_member_detail", "mrasem_admin_back", "mrasem_admin_none",
                    "mrasem_admin_form_save", "mrasem_admin_form_delegation_delete_message",
                    "mrasem_admin_form_member_delete_message", "mrasem_admin_form_item_delete_message",
                    "mrasem_admin_toast_saved_strong", "mrasem_admin_toast_deleted_rest", "mrasem_admin_toast_postponed_rest",
                    "mrasem_admin_action_conflicts_subtitle", "mrasem_admin_action_requests_subtitle",
                    "mrasem_admin_action_gaps_subtitle", "mrasem_admin_movement_subtitle", "mrasem_admin_movement_no_driver"]
        keys += DelegationFilter.allCases.map(\.titleKey) + DelegationStatus.allCases.map(\.labelKey)
        keys += ProgramItemKind.allCases.map(\.labelKey) + MissionMode.allCases.map(\.adminLabelKey)
        keys += DressCode.allCases.map(\.adminLabelKey) + AdminTab.allCases.map(\.labelKey)
        let errors: [StoreValidationError] = [.emptyName, .invalidDate, .invalidTime, .endBeforeStart,
                                              .dateOutsideDelegation, .notFound, .lastAdmin]
        keys += errors.map(\.messageKey)

        for key in keys {
            XCTAssertNotEqual(mrasemString(key), key, "نص ناقص: \(key)")
        }
    }

    // MARK: - مساعد

    private func failure<T>(_ result: Result<T, StoreValidationError>) -> StoreValidationError? {
        if case let .failure(error) = result { return error }
        return nil
    }
}
