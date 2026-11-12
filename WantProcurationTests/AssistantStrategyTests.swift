//
//  AssistantStrategyTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/AssistantStrategyTest.kt
//

import XCTest
@testable import WantProcuration

final class AssistantStrategyTests: XCTestCase {

    private let doha = MrasemDemoData.inbound
    private let london = MrasemDemoData.outbound

    private func reply(
        _ question: String,
        _ mission: Mission? = nil,
        _ dress: DressCode = .formal
    ) -> AssistantReply {
        AssistantStrategy.reply(question, mission: mission ?? doha, dress: dress)
    }

    func testWelcomeUsesCity() {
        guard case let .welcome(dohaCity) = AssistantStrategy.welcome(doha) else {
            return XCTFail("expected a welcome reply")
        }
        XCTAssertEqual(dohaCity, "الدوحة")

        guard case let .welcome(londonCity) = AssistantStrategy.welcome(london) else {
            return XCTFail("expected a welcome reply")
        }
        XCTAssertEqual(londonCity, "لندن")
    }

    func testQuickQuestions() {
        XCTAssertEqual(reply("ماذا ألبس اليوم؟", nil, .bisht), .dress(.bisht))
        XCTAssertEqual(
            reply("متى موعدي القادم؟"),
            .nextItem(
                title: "توقيع مذكرة التفاهم وصورة تذكارية",
                dayLabel: "الثلاثاء ٢٤",
                time: "11:30",
                place: "القاعة ذاتها"
            )
        )
        XCTAssertEqual(
            reply("أين السيارة؟"),
            .carInfo(type: "لكزس LS – أسود", plate: "123456", driver: "أحمد")
        )
        XCTAssertEqual(reply("أريد طلب طعام"), .food(["سنونو", "طلبات", "رفيق"]))
        XCTAssertEqual(reply("تاكسي"), .taxi(["كروة", "أوبر", "تطبيقات مرخّصة أخرى"]))
        XCTAssertEqual(
            reply("أماكن قريبة"),
            .nearbyPlaces(["كورنيش الدوحة", "متحف الفن الإسلامي", "الحي الثقافي كتارا"])
        )
    }

    func testOtherRules() {
        XCTAssertEqual(
            reply("أين الفندق؟"),
            .hotelInfo(
                name: "فندق الإقامة الرسمي",
                area: "الخليج الغربي",
                room: "1204",
                drive: "٨ دقائق إلى الوزارة"
            )
        )
        XCTAssertEqual(
            reply("أحتاج مستشفى"),
            .emergency(number: "999", coordinatorName: "مريم الكعبي", coordinatorPhone: "+974 5555 0456")
        )
        XCTAssertEqual(
            reply("ما برنامج الغد؟", london),
            .nextItem(
                title: "كلمة وفد دولة قطر",
                dayLabel: "الثلاثاء ٨",
                time: "11:00",
                place: "القاعة الرئيسية"
            )
        )
    }

    func testRuleOrderFirstMatchWins() {
        // «زيارة» فيها «زي» فقاعدة الزي تكسب، زي المصدر بالظبط.
        XCTAssertEqual(reply("أريد زيارة"), .dress(.formal))
    }

    func testOutOfScopeIsForwardedAndCreatesQuestion() {
        let repo = newRepository()
        let assistant = AssistantStrategy(repository: repo)

        XCTAssertEqual(assistant.ask("  هل يوجد مسبح؟ "), .forwarded)

        let request = repo.state.requests[0]
        XCTAssertEqual(request.kind, .question)
        XCTAssertEqual(request.text, "هل يوجد مسبح؟")
        XCTAssertEqual(assistant.conversation().count, 3)
        XCTAssertEqual(assistant.conversation()[1], .user("هل يوجد مسبح؟"))
    }

    func testBlankIsIgnoredAndModeChangeClearsChat() {
        let repo = newRepository()
        let assistant = AssistantStrategy(repository: repo)

        XCTAssertNil(assistant.ask("   "))
        assistant.ask("تاكسي")
        XCTAssertEqual(repo.state.chat.count, 2)
        XCTAssertTrue(repo.state.requests.isEmpty)

        session(repo).changeMode(.outbound)
        XCTAssertTrue(repo.state.chat.isEmpty)

        guard case let .bot(reply) = assistant.conversation()[0] else {
            return XCTFail("expected a bot message")
        }
        XCTAssertEqual(reply, .welcome(city: "لندن"))
    }
}
