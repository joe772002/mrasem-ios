//
//  MissionSummaryStrategyTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/MissionSummaryStrategyTest.kt
//

import XCTest
@testable import WantProcuration

@MainActor
final class MissionSummaryStrategyTests: XCTestCase {

    func testCountdownBeforeArrival() {
        let repo = newRepository()
        let strategy = summaryStrategy(repo, at: "2026-11-11")
        XCTAssertEqual(strategy.summary().countdown, .daysLeft(12))
    }

    func testArrivalDayShowsToday() {
        let repo = newRepository()
        XCTAssertEqual(summaryStrategy(repo, at: "2026-11-23").summary().countdown, .today)
        XCTAssertEqual(summaryStrategy(repo, at: "2026-11-30").summary().countdown, .today)
    }

    func testDurationAndOfficialCountBothModes() {
        let repo = newRepository()
        let strategy = summaryStrategy(repo, at: "2026-11-11")

        var summary = strategy.summary()
        XCTAssertEqual(summary.durationDays, 3)
        XCTAssertEqual(summary.officialCount, 9)

        session(repo).changeMode(.outbound)
        summary = strategy.summary()
        XCTAssertEqual(summary.durationDays, 4)
        XCTAssertEqual(summary.officialCount, 9)
        XCTAssertEqual(summary.countdown, .daysLeft(26))
    }

    func testArrivalCycleStopsAtFourAndIsPerMode() {
        let repo = newRepository()
        let strategy = summaryStrategy(repo, at: "2026-11-11")

        XCTAssertEqual(strategy.summary().button, .notifyArrival)
        XCTAssertEqual(strategy.advanceArrival(), 1)
        XCTAssertEqual(strategy.summary().button, .nextStep)
        XCTAssertEqual(strategy.advanceArrival(), 2)
        XCTAssertEqual(strategy.advanceArrival(), 3)
        XCTAssertEqual(strategy.advanceArrival(), 4)
        XCTAssertNil(strategy.advanceArrival())
        XCTAssertEqual(strategy.summary().button, .completed)
        XCTAssertTrue(strategy.summary().arrivalCompleted)

        session(repo).changeMode(.outbound)
        XCTAssertEqual(strategy.summary().arrivalStage, 0)
    }

    func testChangedSectionsFollowMode() {
        let repo = newRepository()
        let visit = VisitUpdateStrategy(repository: repo)
        let form = visit.currentForm()

        var edited = form.data
        edited.driver = "خالد"
        visit.save(VisitForm(data: edited, dress: form.dress))

        let strategy = summaryStrategy(repo, at: "2026-11-11")
        XCTAssertEqual(strategy.summary().changedSections, [.car])

        session(repo).changeMode(.outbound)
        XCTAssertTrue(strategy.summary().changedSections.isEmpty)
    }
}
