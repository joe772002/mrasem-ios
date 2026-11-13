//
//  DressCodeTests.swift
//  WantProcurationTests
//
//  الزي المطلوب لكل فقرة: حقل نصي حر اختياري، بيتحفظ من الأدمن ويظهر عند الضيف.
//

import XCTest
@testable import WantProcuration

final class DressCodeTests: XCTestCase {

    private func official(_ item: ProgramItem?) throws -> ProgramItem.Official {
        guard case .official(let value)? = item else { throw XCTSkip("مش فقرة رسمية") }
        return value
    }

    func testSeedDressCodeReachesGuest() throws {
        let env = AllRolesTestEnv()
        let record = try XCTUnwrap(env.db.programItem("q2"))
        XCTAssertEqual(record.dressCode, "زي رسمي")

        let item = try official(GuestMissionAdapter.programItem(record, env.db))
        XCTAssertEqual(item.dressCode, "زي رسمي")
    }

    func testBlankDressCodeIsSavedAsNil() throws {
        let env = AllRolesTestEnv()
        var draft = ProgramDraft(delegationId: "d1", date: "2026-11-25")
        draft.title = "فقرة بدون زي"
        draft.time = "18:00"
        draft.dressCode = "   "

        let saved = try env.program.save(draft.record(), notify: false).get()
        XCTAssertNil(saved.dressCode)
        let item = try official(GuestMissionAdapter.programItem(saved, env.db))
        XCTAssertNil(item.dressCode)
    }

    func testDressCodeIsTrimmedAndRoundTrips() throws {
        let env = AllRolesTestEnv()
        var draft = ProgramDraft(delegationId: "d1", date: "2026-11-25")
        draft.title = "استقبال"
        draft.time = "19:00"
        draft.dressCode = "  بشت  "

        let saved = try env.program.save(draft.record(), notify: false).get()
        XCTAssertEqual(saved.dressCode, "بشت")
        XCTAssertEqual(ProgramDraft(saved).dressCode, "بشت")
    }

    func testChangingDressCodeCountsAsContentChange() throws {
        let env = AllRolesTestEnv()
        let original = try XCTUnwrap(env.db.programItem("p3"))
        var draft = ProgramDraft(original)
        draft.dressCode = "كاجوال"

        let saved = try env.program.save(draft.record(), notify: false).get()
        XCTAssertEqual(saved.dressCode, "كاجوال")
        XCTAssertTrue(saved.isChanged)
    }

    func testRecordsSavedBeforeTheFieldStillDecode() throws {
        let json = """
        {"id":"x","delegationId":"d1","date":"2026-11-24","time":"10:00","title":"قديمة","kind":"meal",
         "note":"","isKey":false,"isChanged":false}
        """
        let record = try JSONDecoder().decode(ProgramItemRecord.self, from: Data(json.utf8))
        XCTAssertNil(record.dressCode)
    }
}
