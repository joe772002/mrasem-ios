//
//  MissionPlanStateTests.swift
//  WantProcurationTests
//
//  Phase 4 (no Android counterpart: the Kotlin ViewModels have no unit tests, so these
//  guard the state mapping, the arrival toasts and the Plan chip routing).
//

import XCTest
import Combine
@testable import WantProcuration

final class MissionPlanStateTests: XCTestCase {

    func testArrivalToastMatchesEveryStage() {
        func text(_ stage: Int) -> String {
            let toast = MissionViewModel.arrivalToast(stage: stage, receiverName: "أحمد")
            return toast.strong.resolve() + "|" + (toast.rest?.resolve() ?? "")
        }
        XCTAssertEqual(text(1), "تم إبلاغ المستقبِل والسائق.|أحمد بانتظارك.")
        XCTAssertEqual(text(2), "السائق في الطريق|إلى نقطة الالتقاء.")
        XCTAssertEqual(text(3), "أهلاً بك.|جارٍ التوجه إلى الفندق.")
        XCTAssertEqual(text(4), "وصلت إلى الفندق.|نتمنى لك إقامة طيبة.")
        XCTAssertEqual(text(9), text(4))
    }

    func testMissionStateFollowsTheRepository() {
        let repo = newRepository()
        let summary = summaryStrategy(repo)
        var state = MissionUiState.make(repo.state, summary: summary)
        XCTAssertEqual(state.mission.mode, .inbound)
        XCTAssertEqual(state.summary.arrivalStage, 0)
        XCTAssertEqual(state.summary.button, .notifyArrival)
        XCTAssertTrue(state.summary.changedSections.isEmpty)
        XCTAssertTrue(state.notices.isEmpty)

        _ = summary.advanceArrival()
        state = MissionUiState.make(repo.state, summary: summary)
        XCTAssertEqual(state.summary.arrivalStage, 1)
        XCTAssertEqual(state.summary.button, .nextStep)

        session(repo).changeMode(.outbound)
        state = MissionUiState.make(repo.state, summary: summary)
        XCTAssertEqual(state.mission.mode, .outbound)
        XCTAssertEqual(state.summary.arrivalStage, 0)
    }

    func testArrivalClickAdvancesTheStageAndShowsTheToast() {
        let repo = newRepository()
        let bus = MrasemToastBus()
        let viewModel = MissionViewModel(session: session(repo), summary: summaryStrategy(repo), toastBus: bus)
        var toasts: [String] = []
        let token = bus.events.sink { toasts.append($0.strong.resolve()) }

        for _ in 0..<4 { viewModel.onArrivalClick() }
        XCTAssertEqual(viewModel.uiState.summary.arrivalStage, 4)
        XCTAssertTrue(viewModel.uiState.summary.arrivalCompleted)
        XCTAssertEqual(toasts, ["تم إبلاغ المستقبِل والسائق.", "السائق في الطريق", "أهلاً بك.", "وصلت إلى الفندق."])

        viewModel.onArrivalClick()
        XCTAssertEqual(toasts.count, 4, "a completed arrival must not toast again")
        token.cancel()
    }

    func testPlanStateFollowsTheSelectedDay() {
        let repo = newRepository()
        let program = ProgramStrategy(repository: repo)
        var state = PlanUiState.make(repo.state, program: program)
        XCTAssertEqual(state.dayLabels.count, repo.state.mission.days.count)
        XCTAssertEqual(state.timeline.dayIndex, 1)
        XCTAssertEqual(state.timeZone, repo.state.mission.timeZone)

        session(repo).selectDay(0)
        state = PlanUiState.make(repo.state, program: program)
        XCTAssertEqual(state.timeline.dayIndex, 0)
        XCTAssertEqual(state.timeline.entries.count, repo.state.mission.days[0].items.count)
    }

    func testPlanViewModelRoutesTheChips() {
        let repo = newRepository()
        let viewModel = PlanViewModel(session: session(repo), program: ProgramStrategy(repository: repo))

        viewModel.onDaySelected(0)
        XCTAssertEqual(viewModel.uiState.timeline.dayIndex, 0)

        viewModel.onKeyCardClick()
        XCTAssertEqual(repo.state.guestTab, .`protocol`)

        viewModel.onFreeTimeSuggestionClick()
        XCTAssertEqual(repo.state.guestTab, .explore)
        XCTAssertEqual(repo.state.filter, .all)
    }

    func testEveryMissionAndPlanStringKeyResolves() {
        let keys = [
            "mrasem_mission_stat_days_left", "mrasem_mission_stat_today", "mrasem_mission_stat_arrival_day",
            "mrasem_mission_stat_duration", "mrasem_mission_stat_official", "mrasem_mission_kv_timezone",
            "mrasem_mission_kv_currency", "mrasem_mission_kv_weather", "mrasem_arrival_title",
            "mrasem_arrival_step_landed", "mrasem_arrival_step_hotel", "mrasem_arrival_button_notify",
            "mrasem_arrival_button_next", "mrasem_arrival_button_completed", "mrasem_pill_done", "mrasem_pill_updated",
            "mrasem_receiver_title", "mrasem_receiver_kv_phone", "mrasem_receiver_kv_spot", "mrasem_action_call",
            "mrasem_action_whatsapp", "mrasem_car_title", "mrasem_venue_title", "mrasem_venue_kv_area",
            "mrasem_venue_kv_entrance", "mrasem_venue_kv_floor", "mrasem_venue_kv_hall", "mrasem_venue_kv_parking",
            "mrasem_venue_open_maps", "mrasem_map_hotel", "mrasem_stay_title", "mrasem_stay_kv_hotel",
            "mrasem_stay_kv_room", "mrasem_stay_kv_breakfast", "mrasem_stay_kv_distance", "mrasem_pass_title",
            "mrasem_pass_qr_description", "mrasem_emergency_title", "mrasem_plan_title", "mrasem_plan_changed",
            "mrasem_plan_key_card",
        ]
        for key in keys {
            XCTAssertNotEqual(mrasemString(key), key, "missing string: \(key)")
        }
        XCTAssertEqual(mrasemString("mrasem_stay_hotel_value", ["فندق", "الدوحة"]), "فندق – الدوحة")
        XCTAssertEqual(mrasemString("mrasem_plan_free_until", ["14:00"]).contains("14:00"), true)
    }
}
