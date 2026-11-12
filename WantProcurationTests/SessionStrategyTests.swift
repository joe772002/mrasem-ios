//
//  SessionStrategyTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/SessionStrategyTest.kt
//

import XCTest
@testable import WantProcuration

final class SessionStrategyTests: XCTestCase {

    func testRestoresSavedGuestTab() {
        let repo = newRepository()
        let strategy = MrasemSessionStrategy(repository: repo, preferences: FakePreferences(initial: .`protocol`))
        strategy.restoreGuestTab()
        XCTAssertEqual(repo.state.guestTab, .`protocol`)
    }

    func testNothingSavedKeepsMission() {
        let repo = newRepository()
        MrasemSessionStrategy(repository: repo, preferences: FakePreferences()).restoreGuestTab()
        XCTAssertEqual(repo.state.guestTab, .mission)
    }

    func testPersistsTab() {
        let prefs = FakePreferences()
        MrasemSessionStrategy(repository: newRepository(), preferences: prefs).persistGuestTab(.assistant)
        XCTAssertEqual(prefs.saved, .assistant)
    }
}
