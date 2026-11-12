//
//  OfficeModel+WorkingHours.swift
//  WantProcuration
//
//  "Open now" / "Closed now" from the office's working hours (fromTime – toTime), Cairo time.
//  Shown on the office card in the list; the working hours inside the office details are unchanged.
//

import Foundation

extension OfficeModel {
    /// true = open now, false = closed now, nil = hours missing or unreadable (no badge is shown).
    var isOpenNow: Bool? {
        isOpen(at: Date())
    }

    func isOpen(at date: Date) -> Bool? {
        guard let from = Self.minutes(fromTime), let to = Self.minutes(toTime), from != to else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let now = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if from < to {
            return now >= from && now < to
        }
        // Hours that pass midnight, e.g. 18:00 – 02:00.
        return now >= from || now < to
    }

    /// Minutes since midnight from "16:00", "4:00 PM", "04:00:00" or "٤:٠٠ م". nil when unreadable.
    static func minutes(_ text: String) -> Int? {
        let value = NationalIDParser.normalizeDigits(text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = value.firstMatch(of: #/(\d{1,2}):(\d{2})/#),
              var hour = Int(match.1), let minute = Int(match.2),
              hour < 24, minute < 60 else { return nil }
        let lower = value.lowercased()
        let isPM = lower.contains("pm") || value.contains("م")
        let isAM = lower.contains("am") || value.contains("ص")
        if isPM && hour < 12 { hour += 12 }
        if isAM && hour == 12 { hour = 0 }
        return hour * 60 + minute
    }
}
