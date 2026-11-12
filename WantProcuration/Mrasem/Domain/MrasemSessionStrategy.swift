//
//  MrasemSessionStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/MrasemSessionStrategy.kt
//

import Foundation
import Combine

/// التنقل العام: الوضع، الدور، التابات، اليوم، الفلتر + حفظ آخر تاب للضيف.
final class MrasemSessionStrategy {
    private let repository: MissionRepository
    private let preferences: MrasemPreferences

    init(repository: MissionRepository, preferences: MrasemPreferences) {
        self.repository = repository
        self.preferences = preferences
    }

    var statePublisher: AnyPublisher<MrasemState, Never> {
        repository.statePublisher
    }

    var state: MrasemState { repository.state }

    /// اليوم الافتراضي: inbound = اليوم الثاني، outbound = اليوم الأول.
    func defaultDay(_ mode: MissionMode) -> Int {
        mode == .inbound ? 1 : 0
    }

    /// تغيير الوضع يصفّر اليوم ويمسح المحادثة.
    func changeMode(_ mode: MissionMode) {
        repository.setMode(mode, dayIndex: defaultDay(mode))
    }

    func changeRole(_ role: UserRole) {
        repository.setRole(role)
    }

    func selectGuestTab(_ tab: GuestTab) {
        repository.setGuestTab(tab)
    }

    func selectTeamTab(_ tab: TeamTab) {
        repository.setTeamTab(tab)
    }

    func selectFilter(_ filter: ExploreFilter) {
        repository.setFilter(filter)
    }

    func selectDay(_ index: Int) {
        let days = repository.state.mission.days
        let last = max(days.count - 1, 0)
        repository.setDay(min(max(index, 0), last))
    }

    /// chip اقتراح الوقت الحر ← استكشف بفلتر «الكل».
    func openExploreFromFreeTime() {
        repository.setFilter(.all)
        repository.setGuestTab(.explore)
    }

    /// chip بطاقة الـ ٣٠ ثانية ← البروتوكول.
    func openProtocol() {
        repository.setGuestTab(.protocol)
    }

    /// يرجّع آخر تاب اتحفظ (لو فيه).
    func restoreGuestTab() {
        guard let tab = preferences.lastGuestTab else { return }
        repository.setGuestTab(tab)
    }

    func persistGuestTab(_ tab: GuestTab) {
        preferences.saveGuestTab(tab)
    }
}
