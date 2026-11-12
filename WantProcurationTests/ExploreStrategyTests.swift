//
//  ExploreStrategyTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/ExploreStrategyTest.kt
//

import XCTest
@testable import WantProcuration

final class ExploreStrategyTests: XCTestCase {

    private func names(_ filter: ExploreFilter, _ mode: MissionMode = .inbound) -> [String] {
        ExploreStrategy.filterPlaces(MrasemDemoData.missions[mode]!.places, filter: filter).map(\.name)
    }

    func testAllIsSortedByMinutes() {
        let all = names(.all)
        XCTAssertEqual(all.count, 8)
        XCTAssertEqual(all.first, "كورنيش الدوحة")
        XCTAssertEqual(all.last, "رحلة صحراوية إلى خور العديد")
        XCTAssertEqual(all, names(.fullDay))
    }

    func testDurationFilters() {
        XCTAssertEqual(names(.oneHour), ["كورنيش الدوحة"])
        XCTAssertEqual(names(.twoHours).count, 7)
        XCTAssertEqual(names(.halfDay).count, 7)
        XCTAssertEqual(names(.oneHour, .outbound), ["حدائق هايد بارك", "نهر التايمز ووستمنستر"])
        XCTAssertEqual(names(.all, .outbound).count, 4)
    }

    func testRequestLifecycle() {
        let repo = newRepository()
        let explore = ExploreStrategy(repository: repo)
        let place = "سوق واقف"

        func stateOf() -> PlaceRequestState {
            explore.items().first { $0.place.name == place }!.requestState
        }

        XCTAssertEqual(stateOf(), .available)
        XCTAssertTrue(explore.requestVisit(place))
        XCTAssertEqual(stateOf(), .pending)
        XCTAssertFalse(explore.requestVisit(place))
        XCTAssertEqual(repo.state.requests.count, 1)

        TeamStrategy(repository: repo).resolveRequest(repo.state.requests[0].id)
        XCTAssertEqual(stateOf(), .arranged)
    }

    func testPluralHours() {
        let repo = newRepository()
        let items = ExploreStrategy(repository: repo).items()
        XCTAssertTrue(items.first { $0.place.name == "رحلة صحراوية إلى خور العديد" }!.pluralHours)
        XCTAssertFalse(items.first { $0.place.name == "سوق واقف" }!.pluralHours)
    }

    func testFitsRespectsDurationForEveryFilter() {
        let places = MrasemDemoData.inbound.places
        // ساعة: المدة ≤ 1
        XCTAssertTrue(places.filter { ExploreStrategy.fits($0, filter: .oneHour) }.allSatisfy { $0.durationHours <= 1 })
        // ساعتان: المدة ≤ 2
        XCTAssertTrue(places.filter { ExploreStrategy.fits($0, filter: .twoHours) }.allSatisfy { $0.durationHours <= 2 })
        // نصف يوم: المدة ≤ 4
        XCTAssertTrue(places.filter { ExploreStrategy.fits($0, filter: .halfDay) }.allSatisfy { $0.durationHours <= 4 })
        // الكل ويوم كامل: كل الأماكن
        XCTAssertEqual(places.count, places.filter { ExploreStrategy.fits($0, filter: .all) }.count)
        XCTAssertEqual(places.count, places.filter { ExploreStrategy.fits($0, filter: .fullDay) }.count)
    }

    func testRequestVisitIsScopedToCurrentMode() {
        let repo = newRepository()
        let explore = ExploreStrategy(repository: repo)
        let place = "سوق واقف"

        XCTAssertTrue(explore.requestVisit(place))
        // الطلب اتسجل للوضع الحالي (inbound) بس.
        XCTAssertEqual(repo.state.requests(for: .inbound).count, 1)
        XCTAssertEqual(repo.state.requests(for: .outbound).count, 0)
    }
}
