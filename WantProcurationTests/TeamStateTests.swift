//
//  TeamStateTests.swift
//  WantProcurationTests
//
//  Phase 7 — حالات شاشات الفريق (الـ UiState الصافي من غير SwiftUI).
//

import XCTest
@testable import WantProcuration

final class TeamStateTests: XCTestCase {

    private struct Env {
        let repo: InMemoryMissionRepository
        let session: MrasemSessionStrategy
        let team: TeamStrategy
        let visit: VisitUpdateStrategy
    }

    private func setup() -> Env {
        let repo = newRepository()
        return Env(
            repo: repo,
            session: session(repo),
            team: TeamStrategy(repository: repo),
            visit: VisitUpdateStrategy(repository: repo)
        )
    }

    func testHeaderFollowsSelectedTeamTab() {
        let env = setup()
        env.session.selectTeamTab(.requests)
        let header = TeamHeaderUi.make(env.repo.state, team: env.team)
        XCTAssertEqual(header.tab, .requests)
    }

    func testVisitFormStartsFromCurrentValues() {
        let env = setup()
        let state = TeamVisitUiState.make(env.repo.state, team: env.team, visit: env.visit)
        XCTAssertEqual(state.form.data, VisitUpdateStrategy.visitData(env.repo.state.mission))
        XCTAssertEqual(state.guest, env.repo.state.mission.guest)
    }

    func testRequestsStateFollowsResolve() {
        let env = setup()
        let explore = ExploreStrategy(repository: env.repo)
        XCTAssertTrue(explore.requestVisit(env.repo.state.mission.places[0].name))

        var state = TeamRequestsUiState.make(env.repo.state, team: env.team)
        XCTAssertEqual(state.requests.count, 1)
        XCTAssertEqual(state.header.kpis.newRequests, 1)

        XCTAssertTrue(env.team.resolveRequest(state.requests[0].id))
        state = TeamRequestsUiState.make(env.repo.state, team: env.team)
        XCTAssertEqual(state.requests[0].status, .done)
        XCTAssertEqual(state.header.kpis.newRequests, 0)
    }

    func testChangesStateShowsKeyItemAndBroadcastRejectsBlank() {
        let env = setup()
        let state = TeamChangesUiState.make(env.repo.state, team: env.team)
        XCTAssertNotNil(state.keyItem)
        XCTAssertFalse(env.team.broadcast("   "))
    }

    func testArchiveStateMatchesMissionInBothModes() {
        let env = setup()
        for mode in MissionMode.allCases {
            env.session.changeMode(mode)
            let state = TeamArchiveUiState.make(env.repo.state, team: env.team)
            XCTAssertEqual(state.archive.guest, env.repo.state.mission.guest)
            XCTAssertEqual(state.archive.officialCount, env.repo.state.mission.officialCount)
        }
    }
}
