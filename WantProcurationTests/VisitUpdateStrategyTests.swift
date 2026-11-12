//
//  VisitUpdateStrategyTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/VisitUpdateStrategyTest.kt
//

import XCTest
@testable import WantProcuration

final class VisitUpdateStrategyTests: XCTestCase {

    func testSaveWithoutChanges() {
        let repo = newRepository()
        let visit = VisitUpdateStrategy(repository: repo)
        XCTAssertEqual(visit.save(visit.currentForm()), .noChanges)
        XCTAssertTrue(repo.state.notices.isEmpty)
    }

    func testBlankFieldsKeepOldValuesAndAreNotChanges() {
        let repo = newRepository()
        let visit = VisitUpdateStrategy(repository: repo)
        let form = visit.currentForm()

        var blank = form.data
        blank.receiverName = "  "
        blank.carPlate = ""

        XCTAssertEqual(visit.save(VisitForm(data: blank, dress: form.dress)), .noChanges)
        XCTAssertEqual(repo.state.mission.receiver.name, "سعيد المري")
        XCTAssertTrue(repo.state.changed.isEmpty)
    }

    func testSavedChangesReachGuestData() {
        let repo = newRepository()
        let visit = VisitUpdateStrategy(repository: repo)
        let form = visit.currentForm()

        var edited = form.data
        edited.receiverPhone = " +974 5555 9999 "
        edited.hall = "قاعة ٢"

        let result = visit.save(VisitForm(data: edited, dress: form.dress))
        XCTAssertEqual(result, .saved(sections: [.receiver, .venue], dressChanged: false))

        let mission = repo.state.mission
        XCTAssertEqual(mission.receiver.phone, "+974 5555 9999")
        XCTAssertEqual(mission.venue.hall, "قاعة ٢")
        XCTAssertEqual(repo.state.notices.first?.content, .visitDataUpdated)
        XCTAssertTrue(repo.state.changed.contains(.section(mode: .inbound, section: .receiver)))
        XCTAssertEqual(mission.venue.building, "مبنى وزارة العدل")
    }

    func testDressChangeOnly() {
        let repo = newRepository()
        let visit = VisitUpdateStrategy(repository: repo)
        let form = visit.currentForm()

        let result = visit.save(VisitForm(data: form.data, dress: .bisht))
        XCTAssertEqual(result, .saved(sections: [], dressChanged: true))
        XCTAssertEqual(repo.state.dress, .bisht)
        XCTAssertEqual(repo.state.notices.first?.content, .dressApproved(.bisht))
        XCTAssertEqual(ProtocolStrategy(repository: repo).content().dress.title, "الزي الوطني مع البشت")
    }

    func testEditsArePerMode() {
        let repo = newRepository()
        let visit = VisitUpdateStrategy(repository: repo)
        session(repo).changeMode(.outbound)

        let form = visit.currentForm()
        var edited = form.data
        edited.receiverPhone = "+44 20 0000 0000"
        visit.save(VisitForm(data: edited, dress: form.dress))

        XCTAssertEqual(repo.state.missions[.outbound]?.receiver.phone, "+44 20 0000 0000")
        XCTAssertEqual(repo.state.missions[.inbound]?.receiver.phone, "+974 5555 0123")
    }
}
