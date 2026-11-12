//
//  TeamGuestLinkingTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/TeamGuestLinkingTest.kt
//
//  Phase 7 — اختبار الربط الكامل: تعديل من الفريق يظهر عند الضيف، في الوضعين (03-PHASES).
//  الضيف والفريق بيقروا من نفس الـ repository (قاعدة A5).
//

import XCTest
@testable import WantProcuration

@MainActor
final class TeamGuestLinkingTests: XCTestCase {

    private let blank = VisitData(
        receiverName: "",
        receiverPhone: "",
        carType: "",
        carPlate: "",
        driver: "",
        hall: "",
        floor: ""
    )

    private func forEachMode(_ block: (Env) -> Void) {
        for mode in MissionMode.allCases {
            let env = Env()
            env.session.changeMode(mode)
            block(env)
        }
    }

    final class Env {
        let repo = newRepository()
        let session = MrasemSessionStrategy(repository: repo, preferences: FakePreferences())
        let team = TeamStrategy(repository: repo)
        let visit = VisitUpdateStrategy(repository: repo)
        let program = ProgramStrategy(repository: repo)
        let explore = ExploreStrategy(repository: repo)
        let protocol = ProtocolStrategy(repository: repo)
        let summary = MissionSummaryStrategy(repository: repo, now: { dateAt("2026-01-01") })

        var mode: MissionMode { repo.state.mode }
    }

    /// 1) «محدَّث» على بطاقة المهمة + القيمة الجديدة + Notice.
    func testVisitSaveShowsUpdatedPillAndNotice() {
        forEachMode { env in
            var edited = self.blank
            edited.receiverName = "مستقبل جديد"

            let result = env.visit.save(VisitForm(data: edited, dress: .formal))
            guard case .saved = result else {
                return XCTFail("expected a saved result")
            }

            let state = env.repo.state
            XCTAssertEqual(state.mission.receiver.name, "مستقبل جديد")
            XCTAssertEqual(env.summary.summary().changedSections, [.receiver])
            XCTAssertEqual(state.recentNotices().first?.content, .visitDataUpdated)
            XCTAssertEqual(env.team.kpis().sentUpdates, 1)
        }
    }

    /// 2) التأجيل يغيّر الموعد في البرنامج ويعلّمه changed.
    func testPostponeChangesPlanTimeline() {
        forEachMode { env in
            let ref = ProgramStrategy.keyItem(env.repo.state.mission)!
            let result = env.program.postponeKeyItem()!
            env.session.selectDay(ref.dayIndex)

            let entries = env.program.timeline().entries
            guard case let .official(entry) = entries[ref.itemIndex] else {
                return XCTFail("expected an official entry")
            }

            XCTAssertEqual(entry.item.time, ProgramStrategy.addMinutes(ref.item.time, 30))
            XCTAssertEqual(entry.item.time, result.newTime)
            XCTAssertTrue(entry.changed)
            XCTAssertEqual(
                env.repo.state.recentNotices().first?.content,
                .postponed(title: ref.item.title, newTime: result.newTime)
            )
        }
    }

    /// 3) طلب من استكشف ← يظهر عند الفريق ← «تم الترتيب» ← الحالة عند الضيف.
    func testExploreRequestRoundTrip() {
        forEachMode { env in
            let place = env.repo.state.mission.places.first!.name
            XCTAssertTrue(env.explore.requestVisit(place))

            func stateOf() -> PlaceRequestState {
                env.explore.items().first { $0.place.name == place }!.requestState
            }

            XCTAssertEqual(stateOf(), .pending)
            XCTAssertEqual(env.team.kpis().newRequests, 1)

            let request = env.team.requests().first!
            XCTAssertEqual(request.mode, env.mode)
            XCTAssertTrue(env.team.resolveRequest(request.id))
            XCTAssertEqual(stateOf(), .arranged)
            XCTAssertEqual(env.repo.state.recentNotices().first?.content, .requestResolved(place: place))
            XCTAssertEqual(env.team.kpis().newRequests, 0)
        }
    }

    /// 4) تغيير زي اليوم يظهر في البروتوكول.
    func testDressChangeReachesProtocol() {
        forEachMode { env in
            env.visit.save(VisitForm(data: self.blank, dress: .bisht))
            XCTAssertEqual(env.protocol.content().dressCode, .bisht)
            XCTAssertEqual(env.repo.state.recentNotices().first?.content, .dressApproved(.bisht))
        }
    }

    /// 5) التنبيه العام يوصل للضيف في نفس الوضع بس.
    func testBroadcastIsScopedToMode() {
        forEachMode { env in
            XCTAssertTrue(env.team.broadcast("تغيير المدخل"))
            XCTAssertEqual(
                env.repo.state.recentNotices().first?.content,
                .broadcast("تغيير المدخل")
            )

            let other = MissionMode.allCases.first { $0 != env.mode }!
            env.session.changeMode(other)
            XCTAssertTrue(env.repo.state.recentNotices().isEmpty)
        }
    }
}
