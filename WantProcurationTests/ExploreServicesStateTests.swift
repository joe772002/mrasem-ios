//
//  ExploreServicesStateTests.swift
//  WantProcurationTests
//
//  Phase 5 (no Android counterpart for the ViewModels): guards the state mapping,
//  the filter / request flow and the services model.
//

import XCTest
import Combine
@testable import WantProcuration

final class ExploreServicesStateTests: XCTestCase {

    func testExploreStateListsFilteredPlacesSortedByMinutes() {
        let repo = newRepository()
        let explore = ExploreStrategy(repository: repo)
        let state = ExploreUiState.make(repo.state, explore: explore)

        XCTAssertEqual(state.filters, ExploreFilter.allCases)
        XCTAssertEqual(state.selectedFilterIndex, 0)
        XCTAssertEqual(state.hotelName, repo.state.mission.hotel.name)
        XCTAssertEqual(state.items.map(\.minutes), state.items.map(\.minutes).sorted())
        XCTAssertTrue(state.items.allSatisfy { $0.requestState == .available })
    }

    func testFilterSelectionNarrowsTheList() {
        let repo = newRepository()
        let toasts = MrasemToastBus()
        let viewModel = ExploreViewModel(
            session: session(repo),
            explore: ExploreStrategy(repository: repo),
            toastBus: toasts
        )
        let all = viewModel.uiState.items.count

        viewModel.onFilterSelected(1)
        XCTAssertEqual(viewModel.uiState.selectedFilterIndex, 1)
        XCTAssertTrue(viewModel.uiState.items.allSatisfy { $0.durationHours <= 1 })
        XCTAssertLessThanOrEqual(viewModel.uiState.items.count, all)

        viewModel.onFilterSelected(99)
        XCTAssertEqual(viewModel.uiState.selectedFilterIndex, 1, "an out-of-range index is ignored")
    }

    func testRequestVisitMarksPendingAndToastsOnce() {
        let repo = newRepository()
        let bus = MrasemToastBus()
        let viewModel = ExploreViewModel(
            session: session(repo),
            explore: ExploreStrategy(repository: repo),
            toastBus: bus
        )
        var toasts: [String] = []
        let token = bus.events.sink { toasts.append($0.strong.resolve() + "|" + ($0.rest?.resolve() ?? "")) }

        let name = viewModel.uiState.items[0].placeName
        viewModel.onRequestVisit(name)
        XCTAssertEqual(viewModel.uiState.items.first { $0.placeName == name }?.requestState, .pending)
        XCTAssertEqual(toasts.count, 1)
        XCTAssertEqual(toasts[0], mrasemString("mrasem_explore_toast_strong") + "|" + mrasemString("mrasem_explore_toast_rest"))

        viewModel.onRequestVisit(name)
        XCTAssertEqual(toasts.count, 1, "a second request for the same place must not toast again")
        token.cancel()
    }

    func testExploreLabelsResolve() {
        let keys = [
            "mrasem_explore_footer", "mrasem_explore_sort_by", "mrasem_explore_filter_all",
            "mrasem_explore_filter_1h", "mrasem_explore_filter_2h", "mrasem_explore_filter_half_day",
            "mrasem_explore_filter_full_day", "mrasem_explore_action_visit", "mrasem_explore_action_pending",
            "mrasem_explore_action_arranged", "mrasem_explore_meta_vip", "mrasem_service_open",
            "mrasem_services_quick_info",
        ]
        for key in keys {
            XCTAssertNotEqual(mrasemString(key), key, "missing string: \(key)")
        }
        XCTAssertTrue(mrasemString("mrasem_explore_meta_minutes", ["٥"]).contains("٥"))
        XCTAssertTrue(mrasemString("mrasem_explore_about_hotel", ["الفندق"]).contains("الفندق"))
        XCTAssertTrue(mrasemString("mrasem_services_hotel_delivery", ["١٢٠٤"]).contains("١٢٠٤"))
    }

    func testServicesStateMapsBothModes() {
        for mode in [MissionMode.inbound, .outbound] {
            var state = MrasemState(missions: MrasemDemoData.missions)
            state.mode = mode
            let ui = ServicesUiState.make(state)
            let mission = state.mission

            XCTAssertEqual(ui.categories.count, mission.services.count)
            XCTAssertEqual(ui.quickInfo.count, mission.quickInfo.count)
            XCTAssertEqual(ui.hotelRoom, mission.hotel.room)
            for (category, source) in zip(ui.categories, mission.services) {
                XCTAssertEqual(category.apps.count, source.apps.count)
                for (app, sourceApp) in zip(category.apps, source.apps) {
                    XCTAssertEqual(app.logoLetter.count, 1)
                    XCTAssertEqual(app.nameEn == nil, sourceApp.nameEn == sourceApp.name)
                    XCTAssertEqual(app.url, sourceApp.url)
                }
            }
        }
    }
}
