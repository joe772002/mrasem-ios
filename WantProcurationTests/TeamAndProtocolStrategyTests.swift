//
//  TeamAndProtocolStrategyTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/TeamAndProtocolStrategyTest.kt
//

import XCTest
@testable import WantProcuration

@MainActor
final class TeamAndProtocolStrategyTests: XCTestCase {

    func testKpisAndResolve() {
        let repo = newRepository()
        let team = TeamStrategy(repository: repo)

        ExploreStrategy(repository: repo).requestVisit("سوق واقف")
        AssistantStrategy(repository: repo).ask("سؤال غير معروف")

        XCTAssertEqual(team.kpis(), TeamKpis(arrivalStage: 0, newRequests: 2, sentUpdates: 0))

        let question = team.requests().last!
        XCTAssertTrue(team.resolveRequest(question.id))
        XCTAssertFalse(team.resolveRequest(question.id))
        XCTAssertEqual(repo.state.notices.last?.content, .requestResolved(place: nil))
        XCTAssertEqual(team.kpis(), TeamKpis(arrivalStage: 0, newRequests: 1, sentUpdates: 1))

        team.resolveRequest(team.requests().first!.id)
        XCTAssertEqual(repo.state.notices.last?.content, .requestResolved(place: "سوق واقف"))
    }

    func testBroadcastAndRecentNotices() {
        let repo = newRepository()
        let team = TeamStrategy(repository: repo)

        XCTAssertFalse(team.broadcast("   "))
        team.broadcast("أ")
        team.broadcast("ب")
        team.broadcast(" ج ")

        XCTAssertEqual(
            repo.state.recentNotices().map(\.content),
            [.broadcast("ج"), .broadcast("ب")]
        )

        session(repo).changeMode(.outbound)
        XCTAssertTrue(repo.state.recentNotices().isEmpty)
        XCTAssertEqual(team.kpis().sentUpdates, 0)
    }

    func testArchive() {
        let summary = TeamStrategy(repository: newRepository()).archive()
        XCTAssertEqual(summary.officialCount, 9)
        XCTAssertEqual(summary.host, "وزارة العدل – دولة قطر")
    }

    func testChecklistIsPerMode() {
        let repo = newRepository()
        let protocol = ProtocolStrategy(repository: repo)

        protocol.toggleCheck(0)
        protocol.toggleCheck(3)
        protocol.toggleCheck(99)
        XCTAssertEqual(protocol.content().readyCount, 2)

        protocol.toggleCheck(3)
        XCTAssertEqual(protocol.content().readyCount, 1)

        session(repo).changeMode(.outbound)
        XCTAssertEqual(protocol.content().readyCount, 0)
        XCTAssertFalse(protocol.content().isInbound)

        session(repo).changeMode(.inbound)
        XCTAssertTrue(protocol.content().checklist[0].checked)
    }

    func testSessionNavigation() {
        let repo = newRepository()
        let session = session(repo)

        session.selectFilter(.oneHour)
        session.openExploreFromFreeTime()
        XCTAssertEqual(repo.state.filter, .all)
        XCTAssertEqual(repo.state.guestTab, .explore)

        session.selectDay(10)
        XCTAssertEqual(repo.state.dayIndex, 2)
    }

    func testProtocolContentCarriesDressAndGuides() {
        let repo = newRepository()
        let protocol = ProtocolStrategy(repository: repo)

        let content = protocol.content()
        XCTAssertEqual(content.dressCode, .formal)
        XCTAssertEqual(content.dress.title, "بدلة رسمية داكنة")
        XCTAssertEqual(content.guides.count, 8)
        XCTAssertEqual(content.guides.first, "الزيارات الداخلية")
        XCTAssertEqual(content.customs.count, 4)

        repo.setDress(.bisht)
        let bisht = protocol.content()
        XCTAssertEqual(bisht.dressCode, .bisht)
        XCTAssertEqual(bisht.dress.title, "الزي الوطني مع البشت")
        XCTAssertEqual(bisht.dress.men.count, 3)
    }

    func testAssistantRulesMatchTheSource() {
        let repo = newRepository()
        let assistant = AssistantStrategy(repository: repo)
        let mission = MrasemDemoData.inbound

        // ترتيب الفقرة الرسمية: العنصر رقم 5 في الترتيب العام.
        let schedule = AssistantStrategy.reply("متى موعدي القادم؟", mission: mission, dress: .formal)
        guard case let .nextItem(title, dayLabel, time, place) = schedule else {
            return XCTFail("expected a next item reply")
        }
        // «الفقرة الرسمية رقم 5 في الترتيب العام» = توقيع مذكرة التفاهم (01-DESIGN-SPEC §7.6).
        XCTAssertEqual(title, "توقيع مذكرة التفاهم وصورة تذكارية")
        XCTAssertEqual(dayLabel, "الثلاثاء ٢٤")
        XCTAssertEqual(time, "11:30")
        XCTAssertEqual(place, "القاعة ذاتها")

        // أقرب 3 أماكن مرتبة بزمن الوصول.
        let nearby = AssistantStrategy.reply("أماكن قريبة", mission: mission, dress: .formal)
        guard case let .nearbyPlaces(places) = nearby else {
            return XCTFail("expected a nearby places reply")
        }
        XCTAssertEqual(
            places.sorted(),
            ["كورنيش الدوحة", "متحف الفن الإسلامي", "الحي الثقافي كتارا"].sorted()
        )

        // السؤال خارج النطاق بينحوّل للمنسق ويسجّل طلب «سؤال».
        XCTAssertEqual(assistant.ask("ما رأيك في الطقس؟"), .forwarded)
        XCTAssertEqual(repo.state.requests.count, 1)
        XCTAssertEqual(repo.state.requests.first?.kind, .question)
    }
}
