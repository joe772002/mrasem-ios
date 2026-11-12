//
//  MissionSummaryStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/MissionSummaryStrategy.kt
//

import Foundation

/// العدّاد في الـ Hero: أيام متبقية أو «اليوم».
enum ArrivalCountdown: Equatable {
    case daysLeft(Int)
    /// يوم الوصول أو بعده: «اليوم / موعد الوصول».
    case today
}

/// نص زر حالة الوصول.
enum ArrivalButton {
    /// «وصلت: أبلغ المستقبِل والسائق»
    case notifyArrival
    /// «الخطوة التالية»
    case nextStep
    /// «تم الوصول إلى الفندق» (disabled)
    case completed
}

let arrivalSteps = 4

struct MissionSummary: Equatable {
    let countdown: ArrivalCountdown
    let durationDays: Int
    let officialCount: Int
    /// 0..4
    let arrivalStage: Int
    let button: ArrivalButton
    let changedSections: Set<ChangedSection>

    var arrivalCompleted: Bool { arrivalStage >= arrivalSteps }
}

final class MissionSummaryStrategy {
    private let repository: MissionRepository
    private let now: () -> MrasemDate

    init(repository: MissionRepository, now: @escaping () -> MrasemDate = { MrasemDate.today() }) {
        self.repository = repository
        self.now = now
    }

    func summary(state: MrasemState? = nil) -> MissionSummary {
        let state = state ?? repository.state
        let mission = state.mission
        let stage = state.arrived()

        return MissionSummary(
            countdown: Self.countdown(mission, today: now()),
            durationDays: Self.durationDays(mission),
            officialCount: mission.officialCount,
            arrivalStage: stage,
            button: Self.button(for: stage),
            changedSections: state.changed.compactMap { key in
                guard case let .section(mode, section) = key, mode == state.mode else { return nil }
                return section
            }
        )
    }

    /// يقدّم مرحلة الوصول خطوة. يرجّع المرحلة الجديدة (1..4) لاختيار نص الـ Toast،
    /// أو nil لو الوصول مكتمل أصلاً.
    func advanceArrival() -> Int? {
        let state = repository.state
        let current = state.arrived()
        guard current < arrivalSteps else { return nil }

        let next = current + 1
        repository.setArrival(mode: state.mode, stage: next)
        return next
    }

    static func countdown(_ mission: Mission, today: MrasemDate) -> ArrivalCountdown {
        let left = mission.start.days(since: today)
        return left > 0 ? .daysLeft(left) : .today
    }

    static func durationDays(_ mission: Mission) -> Int {
        mission.end.days(since: mission.start) + 1
    }

    static func button(for stage: Int) -> ArrivalButton {
        if stage <= 0 { return .notifyArrival }
        if stage >= arrivalSteps { return .completed }
        return .nextStep
    }
}
