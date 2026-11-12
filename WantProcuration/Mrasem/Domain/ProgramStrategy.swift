//
//  ProgramStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/ProgramStrategy.kt
//

import Foundation

enum TimelineEntry: Equatable {
    case official(index: Int, item: ProgramItem.Official, changed: Bool)
    case freeTime(item: ProgramItem.FreeTime, suggestions: [Place])
}

struct DayTimeline: Equatable {
    let dayIndex: Int
    let entries: [TimelineEntry]
}

/// الفقرة الرئيسية في «رادار التغييرات» (اليوم الثاني).
struct KeyItemRef: Equatable {
    let dayIndex: Int
    let itemIndex: Int
    let dayLabel: String
    let item: ProgramItem.Official
}

struct PostponeResult: Equatable {
    let title: String
    let newTime: String
}

final class ProgramStrategy {
    private let repository: MissionRepository

    init(repository: MissionRepository) {
        self.repository = repository
    }

    func timeline(state: MrasemState? = nil) -> DayTimeline {
        let state = state ?? repository.state
        let mission = state.mission
        let last = max(mission.days.count - 1, 0)
        let dayIndex = min(max(state.dayIndex, 0), last)

        let entries = mission.days[dayIndex].items.enumerated().map { index, item -> TimelineEntry in
            switch item {
            case let .official(official):
                return .official(
                    index: index,
                    item: official,
                    changed: state.changed.contains(.item(mode: state.mode, dayIndex: dayIndex, itemIndex: index))
                )
            case let .freeTime(freeTime):
                return .freeTime(
                    item: freeTime,
                    suggestions: Self.suggestions(mission.places, hours: freeTime.hours)
                )
            }
        }

        return DayTimeline(dayIndex: dayIndex, entries: entries)
    }

    /// يأجّل الفقرة الرئيسية لليوم الثاني ٣٠ دقيقة، يعلّمها متغيرة، ويضيف Notice.
    func postponeKeyItem(minutes: Int = ProgramStrategy.postponeMinutes) -> PostponeResult? {
        let state = repository.state
        guard let ref = Self.keyItem(state.mission) else { return nil }

        let newTime = Self.addMinutes(ref.item.time, minutes)
        repository.setItemTime(mode: state.mode, dayIndex: ref.dayIndex, itemIndex: ref.itemIndex, time: newTime)
        repository.markChanged([.item(mode: state.mode, dayIndex: ref.dayIndex, itemIndex: ref.itemIndex)])
        repository.addNotice(mode: state.mode, content: .postponed(title: ref.item.title, newTime: newTime))

        return PostponeResult(title: ref.item.title, newTime: newTime)
    }

    static let postponeMinutes = 30
    private static let maxSuggestions = 3
    private static let changesDayIndex = 1
    private static let minutesPerDay = 24 * 60

    /// الأماكن اللي تحقق `dur + min/30 ≤ hours`، بترتيب البيانات، لحد ٣.
    static func suggestions(_ places: [Place], hours: Double) -> [Place] {
        places
            .filter { $0.durationHours + Double($0.minutes) / 30.0 <= hours }
            .prefix(maxSuggestions)
            .map { $0 }
    }

    static func keyItem(_ mission: Mission) -> KeyItemRef? {
        guard let day = mission.days.indices.contains(changesDayIndex) ? mission.days[changesDayIndex] : nil else {
            return nil
        }
        guard let index = day.items.firstIndex(where: { $0.official?.isKey == true }) else { return nil }
        guard let item = day.items[index].official else { return nil }
        return KeyItemRef(dayIndex: changesDayIndex, itemIndex: index, dayLabel: day.label, item: item)
    }

    /// "HH:mm" + دقائق، مع الالتفاف بعد منتصف الليل.
    static func addMinutes(_ time: String, _ minutes: Int) -> String {
        let parts = time.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return time }

        let total = (h * 60 + m + minutes) % minutesPerDay
        let normalized = total < 0 ? total + minutesPerDay : total

        // padding يدوي بدل format عشان الأرقام تفضل لاتينية حتى لو لغة الجهاز عربي.
        let hours = String(normalized / 60)
        let minutesPart = String(normalized % 60)
        let paddedHours = hours.count < 2 ? "0" + hours : hours
        let paddedMinutes = minutesPart.count < 2 ? "0" + minutesPart : minutesPart
        return "\(paddedHours):\(paddedMinutes)"
    }
}
