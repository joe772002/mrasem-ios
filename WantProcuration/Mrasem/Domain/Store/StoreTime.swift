//
//  StoreTime.swift
//  Mrasem
//
//  Phase 12 — المواعيد في القاعدة نص زي البوابة (G8): `yyyy-MM-dd` و `HH:mm`.
//

import Foundation

/// أخطاء التحقق المشتركة لكل الـ services.
enum StoreValidationError: Error, Equatable {
    case emptyName
    case invalidDate
    case invalidTime
    case endBeforeStart
    case dateOutsideDelegation
    case notFound
    /// آخر أدمن ما ينفعش يتحذف أو يتغيّر دوره.
    case lastAdmin
}

nonisolated enum StoreTime {

    /// دقائق من منتصف الليل، أو `nil` لو الصيغة غلط.
    static func minutes(_ time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, parts[0].count <= 2, parts[1].count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              (0..<24).contains(h), (0..<60).contains(m)
        else { return nil }
        return h * 60 + m
    }

    static func isValidTime(_ time: String) -> Bool { minutes(time) != nil }

    /// `HH:mm` (بيلف على ٢٤ ساعة زي البوابة).
    static func format(_ minutes: Int) -> String {
        let m = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", m / 60, m % 60)
    }

    static func add(_ time: String, minutes delta: Int) -> String? {
        minutes(time).map { format($0 + delta) }
    }

    /// تاريخ حقيقي بصيغة `yyyy-MM-dd` (بيرفض ٣٠ فبراير وشهر ١٣).
    static func isValidDate(_ iso: String) -> Bool {
        guard let d = MrasemDate(iso: iso), d.iso == iso else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
        guard let date = calendar.date(from: DateComponents(year: d.year, month: d.month, day: d.day)) else { return false }
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return c.year == d.year && c.month == d.month && c.day == d.day
    }

    /// كل الأيام من `start` لـ `end` (فاضية لو التواريخ غلط أو مقلوبة).
    static func days(from start: String, to end: String) -> [String] {
        guard let a = MrasemDate(iso: start), let b = MrasemDate(iso: end) else { return [] }
        let count = b.days(since: a)
        guard count >= 0, count < 400 else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
        guard let first = calendar.date(from: DateComponents(year: a.year, month: a.month, day: a.day)) else { return [] }

        return (0...count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: first).map {
                let c = calendar.dateComponents([.year, .month, .day], from: $0)
                return MrasemDate(year: c.year ?? 0, month: c.month ?? 0, day: c.day ?? 0).iso
            }
        }
    }

    /// يوم الأسبوع 1 (الأحد) … 7 (السبت).
    static func weekday(_ iso: String) -> Int? {
        guard let d = MrasemDate(iso: iso) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
        guard let date = calendar.date(from: DateComponents(year: d.year, month: d.month, day: d.day)) else { return nil }
        return calendar.component(.weekday, from: date)
    }

    /// «الإثنين ٢٣» زي بيانات مراسم.
    static func dayLabel(_ iso: String) -> String {
        guard let d = MrasemDate(iso: iso), let w = weekday(iso) else { return iso }
        return mrasemString("mrasem_weekday_\(w)") + " " + d.day.toArabicDigits()
    }

    /// ترتيب الفقرات: التاريخ ثم الوقت.
    static func sortKey(_ item: ProgramItemRecord) -> String {
        item.date + " " + format(minutes(item.time) ?? 0)
    }
}

extension String {
    /// النص بعد شيل المسافات من الأطراف.
    var storeTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
