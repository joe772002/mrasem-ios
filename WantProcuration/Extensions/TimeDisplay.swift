//
//  TimeDisplay.swift
//  WantProcuration
//
//  Shows every time in 12-hour format with ص / م (AM / PM in English), e.g. "13:30" → "1:30 م".
//  Display only: the raw API value is what gets sent back when booking.
//

import Foundation

/// nonisolated: also used from Codable models, off the main actor.
nonisolated enum TimeDisplay {
    private static var isArabic: Bool {
        UserDefaults.standard.string(forKey: "selectedLanguage") != "en"
    }

    /// Rewrites every "H:mm" in the text to 12-hour format. Times that already carry AM/PM keep their hour,
    /// and the AM/PM marker is translated to ص/م in Arabic.
    static func twelveHour(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        let pattern = #"(\d{1,2}):(\d{2})(?::\d{2})?(\s*(?:[AaPp]\.?\s?[Mm]\.?|مساءً|مساءا|مساء|صباحًا|صباحا|صباح|ص|م)(?![\p{L}]))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let source = text as NSString
        var result = ""
        var cursor = 0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: source.length)) {
            result += source.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            cursor = match.range.location + match.range.length

            guard let hour = Int(source.substring(with: match.range(at: 1))),
                  let minute = Int(source.substring(with: match.range(at: 2))),
                  hour < 24, minute < 60 else {
                result += source.substring(with: match.range)
                continue
            }

            let isPM: Bool
            let hour12: Int
            if match.range(at: 3).location != NSNotFound {
                // Already 12-hour: keep the hour, normalise the marker.
                let marker = source.substring(with: match.range(at: 3)).lowercased()
                isPM = marker.contains("p") || marker.contains("م")
                hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            } else {
                isPM = hour >= 12
                hour12 = hour % 12 == 0 ? 12 : hour % 12
            }
            let suffix = isArabic ? (isPM ? "م" : "ص") : (isPM ? "PM" : "AM")
            result += String(format: "%d:%02d %@", hour12, minute, suffix)
        }
        result += source.substring(from: cursor)
        return result
    }
}
