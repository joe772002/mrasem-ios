//
//  MrasemTestUtils.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../domain/strategy/mrasem/MrasemTestUtils.kt
//

import Foundation
@testable import WantProcuration

func newRepository() -> InMemoryMissionRepository {
    InMemoryMissionRepository()
}

/// بديل `FakePreferences` — بيحفظ آخر تاب في الذاكرة.
final class FakePreferences: MrasemPreferences {
    private(set) var saved: GuestTab?

    init(initial: GuestTab? = nil) {
        self.saved = initial
    }

    var lastGuestTab: GuestTab? { saved }

    func saveGuestTab(_ tab: GuestTab) {
        saved = tab
    }
}

func session(_ repo: MissionRepository) -> MrasemSessionStrategy {
    MrasemSessionStrategy(repository: repo, preferences: FakePreferences())
}

/// تاريخ ثابت — زي `Clock.fixed` في Kotlin.
func dateAt(_ iso: String) -> MrasemDate {
    MrasemDate(iso: iso)!
}

func summaryStrategy(_ repo: MissionRepository, at iso: String = "2026-11-11") -> MissionSummaryStrategy {
    MissionSummaryStrategy(repository: repo, now: { dateAt(iso) })
}
