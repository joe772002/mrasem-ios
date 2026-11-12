//
//  ShellStateTests.swift
//  WantProcurationTests
//
//  Phase 3 (no Android counterpart: the Kotlin Shell has no unit tests, so these
//  guard the pure parts of it — destinations, shell state, UiText, notice texts,
//  and the string keys the Shell depends on).
//

import XCTest
import Combine
@testable import WantProcuration

final class ShellStateTests: XCTestCase {

    func testDestinationListsMatchTheTabs() {
        XCTAssertEqual(MrasemDestination.guest.count, GuestTab.allCases.count)
        XCTAssertEqual(MrasemDestination.team.count, TeamTab.allCases.count)
        XCTAssertEqual(MrasemDestination.guest, [.mission, .plan, .services, .explore, .`protocol`, .assistant])
        XCTAssertEqual(MrasemDestination.team, [.teamVisit, .teamChanges, .teamRequests, .teamArchive])
        XCTAssertEqual(Set(MrasemDestination.allCases).count, 10)
    }

    func testTabsMapToDestinationsAndBack() {
        for tab in GuestTab.allCases {
            XCTAssertEqual(MrasemDestination.of(tab).guestTab, tab)
            XCTAssertNil(MrasemDestination.of(tab).teamTab)
        }
        for tab in TeamTab.allCases {
            XCTAssertEqual(MrasemDestination.of(tab).teamTab, tab)
            XCTAssertNil(MrasemDestination.of(tab).guestTab)
        }
    }

    func testCurrentFollowsRoleAndTabs() {
        XCTAssertEqual(MrasemDestination.current(role: .guest, guestTab: .assistant, teamTab: .archive), .assistant)
        XCTAssertEqual(MrasemDestination.current(role: .team, guestTab: .assistant, teamTab: .archive), .teamArchive)
        XCTAssertEqual(MrasemDestination.tabs(for: .guest).count, 6)
        XCTAssertEqual(MrasemDestination.tabs(for: .team).count, 4)
    }

    func testEveryShellStringKeyResolves() {
        var keys = MrasemDestination.allCases.map(\.labelKey)
        keys += ["mrasem_brand_title", "mrasem_brand_subtitle", "mrasem_role_guest", "mrasem_role_team",
                 "mrasem_mode_inbound", "mrasem_mode_outbound", "mrasem_demo_footer",
                 "mrasem_notice_title", "mrasem_placeholder_message"]
        for key in keys {
            let text = mrasemString(key)
            XCTAssertNotEqual(text, key, "missing string: \(key)")
            XCTAssertFalse(text.isEmpty, key)
        }
        XCTAssertEqual(mrasemString("mrasem_role_guest"), "الضيف")
    }

    func testUiTextResolvesResWithArgsAndRaw() {
        XCTAssertEqual(UiText.raw("نص حرفي").resolve(), "نص حرفي")
        // المعاملات الموضعية %1$@ %2$@، ومن غير شرطة مائلة قبل علامة الاقتباس.
        XCTAssertEqual(
            UiText.res("mrasem_notice_postponed", ["جلسة المباحثات", "10:00"]).resolve(),
            "تأجّل موعد \"جلسة المباحثات\" إلى 10:00. تم إبلاغ السائق والفندق."
        )
        XCTAssertEqual(UiText.res("mrasem_toast_arrival_1_rest", ["أحمد"]).resolve(), "أحمد بانتظارك.")
    }

    func testNoticeTextForEveryContent() {
        XCTAssertEqual(
            mrasemNoticeText(.dressApproved(.bisht)),
            "تم اعتماد زي اليوم: الزي الوطني مع البشت، وتحديث بيانات الزيارة."
        )
        XCTAssertEqual(
            mrasemNoticeText(.dressApproved(.formal)),
            "تم اعتماد زي اليوم: بدلة رسمية، وتحديث بيانات الزيارة."
        )
        XCTAssertEqual(
            mrasemNoticeText(.visitDataUpdated),
            "تم تحديث بيانات الاستقبال أو السيارة أو القاعة. راجع بطاقة المهمة."
        )
        XCTAssertEqual(mrasemNoticeText(.broadcast("اجتماع عاجل")), "اجتماع عاجل")
        XCTAssertEqual(mrasemNoticeText(.requestResolved(place: "متحف الفن الإسلامي")), "تم ترتيب طلبك: متحف الفن الإسلامي")
        XCTAssertEqual(mrasemNoticeText(.requestResolved(place: nil)), "تم ترتيب طلبك: تم الرد على سؤالك")
    }

    func testToastBusDeliversMessages() {
        let bus = MrasemToastBus()
        var received: [String] = []
        let token = bus.events.sink { received.append($0.strong.resolve() + "|" + ($0.rest?.resolve() ?? "")) }

        bus.show(ToastMessage(.raw("قوي"), .raw("وباقي")))
        bus.show(ToastMessage(.res("mrasem_toast_arrival_2_strong")))

        XCTAssertEqual(received, ["قوي|وباقي", "السائق في الطريق|"])
        token.cancel()
    }
}
