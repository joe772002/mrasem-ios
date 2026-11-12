//
//  ProtocolAssistantStateTests.swift
//  WantProcurationTests
//
//  Phase 6 (no Android counterpart for the ViewModels): checklist toggling,
//  guide toast, the assistant conversation and every reply's text.
//

import XCTest
import Combine
@testable import WantProcuration

final class ProtocolAssistantStateTests: XCTestCase {

    private func protocolViewModel(_ repo: InMemoryMissionRepository, bus: MrasemToastBus = MrasemToastBus()) -> ProtocolViewModel {
        ProtocolViewModel(session: session(repo), protocolStrategy: ProtocolStrategy(repository: repo), toastBus: bus)
    }

    func testChecklistToggleUpdatesReadyCount() {
        let repo = newRepository()
        let viewModel = protocolViewModel(repo)
        XCTAssertEqual(viewModel.uiState.content.readyCount, 0)

        viewModel.onCheckToggle(0)
        viewModel.onCheckToggle(2)
        XCTAssertEqual(viewModel.uiState.content.readyCount, 2)
        XCTAssertTrue(viewModel.uiState.content.checklist[0].checked)

        viewModel.onCheckToggle(0)
        XCTAssertEqual(viewModel.uiState.content.readyCount, 1)
    }

    func testChecklistIsKeptPerMode() {
        let repo = newRepository()
        let viewModel = protocolViewModel(repo)
        viewModel.onCheckToggle(1)

        session(repo).changeMode(.outbound)
        XCTAssertEqual(viewModel.uiState.content.readyCount, 0)
        XCTAssertFalse(viewModel.uiState.content.isInbound)

        session(repo).changeMode(.inbound)
        XCTAssertEqual(viewModel.uiState.content.readyCount, 1)
    }

    func testGuideClickShowsOneToast() {
        let repo = newRepository()
        let bus = MrasemToastBus()
        let viewModel = protocolViewModel(repo, bus: bus)
        var toasts: [String] = []
        let token = bus.events.sink { toasts.append($0.strong.resolve()) }

        let guide = viewModel.uiState.content.guides[0]
        viewModel.onGuideClick(guide)
        XCTAssertEqual(toasts, [mrasemString("mrasem_protocol_guide_toast", [guide])])
        token.cancel()
    }

    func testAssistantConversationGrowsWithEachQuestion() {
        let repo = newRepository()
        let viewModel = AssistantViewModel(session: session(repo), assistant: AssistantStrategy(repository: repo))
        XCTAssertEqual(viewModel.uiState.messages.count, 1)
        XCTAssertEqual(viewModel.uiState.quickQuestions, MrasemDemoData.quickQuestions)

        viewModel.onAsk("ماذا ألبس اليوم؟")
        XCTAssertEqual(viewModel.uiState.messages.count, 3)
        XCTAssertEqual(viewModel.uiState.messages[1], .user("ماذا ألبس اليوم؟"))

        viewModel.onAsk("   ")
        XCTAssertEqual(viewModel.uiState.messages.count, 3, "a blank question is ignored")
    }

    func testUnknownQuestionIsForwardedToTheCoordinator() {
        let repo = newRepository()
        let viewModel = AssistantViewModel(session: session(repo), assistant: AssistantStrategy(repository: repo))

        viewModel.onAsk("كم عدد سكان البلد؟")
        XCTAssertEqual(viewModel.uiState.messages.last, .bot(.forwarded))
        XCTAssertEqual(repo.state.requests.count, 1)
    }

    func testEveryReplyHasText() {
        let replies: [AssistantReply] = [
            .welcome(city: "الدوحة"),
            .dress(.formal), .dress(.bisht),
            .nextItem(title: "عنوان", dayLabel: "يوم", time: "09:30", place: "مكان"),
            .carInfo(type: "نوع", plate: "123", driver: "سائق"),
            .hotelInfo(name: "فندق", area: "منطقة", room: "غرفة", drive: "١٠ دقائق"),
            .food(["أ", "ب"]), .taxi(["ج"]), .nearbyPlaces(["د", "هـ"]),
            .emergency(number: "999", coordinatorName: "منسق", coordinatorPhone: "+974"),
            .forwarded,
        ]
        for reply in replies {
            let text = mrasemAssistantReplyText(reply)
            XCTAssertFalse(text.isEmpty)
            XCTAssertFalse(text.hasPrefix("mrasem_"), "missing string for \(reply)")
            XCTAssertFalse(text.contains("%"), "unfilled placeholder in \(text)")
        }
        XCTAssertTrue(mrasemAssistantReplyText(.food(["أ", "ب"])).contains("أ، ب"))
    }

    func testProtocolLabelsResolve() {
        let keys = [
            "mrasem_protocol_card_label", "mrasem_protocol_next_meeting", "mrasem_protocol_kv_address",
            "mrasem_protocol_kv_seat", "mrasem_protocol_kv_gift", "mrasem_protocol_kv_lang",
            "mrasem_protocol_dress_title", "mrasem_protocol_dress_approved", "mrasem_protocol_dress_note",
            "mrasem_protocol_men", "mrasem_protocol_women", "mrasem_protocol_checklist_title",
            "mrasem_protocol_customs_inbound", "mrasem_protocol_customs_outbound", "mrasem_protocol_guides_title",
            "mrasem_assistant_title", "mrasem_assistant_demo_label", "mrasem_assistant_placeholder",
            "mrasem_assistant_send",
        ]
        for key in keys {
            XCTAssertNotEqual(mrasemString(key), key, "missing string: \(key)")
        }
        XCTAssertTrue(mrasemString("mrasem_protocol_checklist_ready", ["٢", "٥"]).contains("٢"))
    }
}
