//
//  ProgramStrategyTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/ProgramStrategyTest.kt
//

import XCTest
@testable import WantProcuration

@MainActor
final class ProgramStrategyTests: XCTestCase {

    func testDefaultDayPerMode() {
        let repo = newRepository()
        let session = session(repo)

        XCTAssertEqual(repo.state.dayIndex, 1)
        session.changeMode(.outbound)
        XCTAssertEqual(repo.state.dayIndex, 0)
        session.changeMode(.inbound)
        XCTAssertEqual(repo.state.dayIndex, 1)
    }

    func testFreeTimeSuggestions() {
        let doha = MrasemDemoData.inbound.places
        XCTAssertEqual(
            ProgramStrategy.suggestions(doha, hours: 3.5).map(\.name),
            ["متحف الفن الإسلامي", "كورنيش الدوحة", "سوق واقف"]
        )

        let london = MrasemDemoData.outbound.places
        XCTAssertEqual(
            ProgramStrategy.suggestions(london, hours: 2.0).map(\.name),
            ["نهر التايمز ووستمنستر", "المعرض الوطني", "حدائق هايد بارك"]
        )
    }

    func testFreeTimeWithoutSuggestions() {
        XCTAssertTrue(ProgramStrategy.suggestions(MrasemDemoData.inbound.places, hours: 0.5).isEmpty)
    }

    func testAddMinutesCrossesHourAndMidnight() {
        XCTAssertEqual(ProgramStrategy.addMinutes("09:30", 30), "10:00")
        XCTAssertEqual(ProgramStrategy.addMinutes("09:00", 30), "09:30")
        XCTAssertEqual(ProgramStrategy.addMinutes("23:40", 30), "00:10")
    }

    func testPostponeKeyItemUpdatesTimelineAndNotice() {
        let repo = newRepository()
        let program = ProgramStrategy(repository: repo)

        let result = program.postponeKeyItem()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "جلسة المباحثات الرسمية")
        XCTAssertEqual(result?.newTime, "10:00")

        let entries = program.timeline().entries
        guard case let .official(first) = entries[0] else {
            return XCTFail("expected an official entry")
        }
        XCTAssertEqual(first.item.time, "10:00")
        XCTAssertTrue(first.changed)

        guard case let .official(second) = entries[1] else {
            return XCTFail("expected an official entry")
        }
        XCTAssertFalse(second.changed)

        XCTAssertEqual(
            repo.state.notices.last?.content,
            .postponed(title: "جلسة المباحثات الرسمية", newTime: "10:00")
        )

        program.postponeKeyItem()
        XCTAssertEqual(ProgramStrategy.keyItem(repo.state.mission)?.item.time, "10:30")
    }

    func testPostponeIsPerMode() {
        let repo = newRepository()
        ProgramStrategy(repository: repo).postponeKeyItem()
        session(repo).changeMode(.outbound)

        let key = ProgramStrategy.keyItem(repo.state.mission)
        XCTAssertEqual(key?.item.time, "09:00")
        XCTAssertEqual(key?.dayLabel, "الثلاثاء ٨")

        repo.setDay(1)
        let entries = ProgramStrategy(repository: repo).timeline().entries
        guard case let .official(first) = entries[0] else {
            return XCTFail("expected an official entry")
        }
        XCTAssertFalse(first.changed)
    }

    func testTimelineMarksFreeTime() {
        let repo = newRepository()
        let entries = ProgramStrategy(repository: repo).timeline().entries
        XCTAssertEqual(entries.count, 5)

        guard case let .freeTime(free) = entries[3] else {
            return XCTFail("expected a free time entry")
        }
        XCTAssertEqual(free.item, ProgramItem.FreeTime(from: "14:00", to: "16:30", hours: 2.5))
        XCTAssertEqual(free.suggestions.count, 3)
    }
}
