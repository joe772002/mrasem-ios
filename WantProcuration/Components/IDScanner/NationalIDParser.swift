//
//  NationalIDParser.swift
//  WantProcuration
//
//  Finds and checks an Egyptian national ID (14 digits) inside text read from the card by the camera.
//
//  Structure of the number (left to right):
//    [1] century: 2 = 1900s, 3 = 2000s
//    [2-7] birth date YYMMDD
//    [8-9] governorate code
//    [10-14] serial + check digit
//  We check the century, that the birth date is a real past date, and that the governorate code exists.
//  The check digit is NOT verified here; the backend validates the number right after (validateIdentityNumber).
//

import Foundation

struct NationalIDInfo: Equatable {
    let number: String
    let birthDate: Date
    let governorate: String

    var birthDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: birthDate)
    }

    /// For logs: only the last 4 digits are shown.
    var masked: String { String(repeating: "•", count: 10) + number.suffix(4) }
}

enum NationalIDParser {

    static let governorates: [String: String] = [
        "01": "القاهرة", "02": "الإسكندرية", "03": "بورسعيد", "04": "السويس",
        "11": "دمياط", "12": "الدقهلية", "13": "الشرقية", "14": "القليوبية",
        "15": "كفر الشيخ", "16": "الغربية", "17": "المنوفية", "18": "البحيرة",
        "19": "الإسماعيلية", "21": "الجيزة", "22": "بني سويف", "23": "الفيوم",
        "24": "المنيا", "25": "أسيوط", "26": "سوهاج", "27": "قنا",
        "28": "أسوان", "29": "الأقصر", "31": "البحر الأحمر", "32": "الوادي الجديد",
        "33": "مطروح", "34": "شمال سيناء", "35": "جنوب سيناء", "88": "خارج الجمهورية"
    ]

    /// Arabic-Indic (٠-٩) and Persian (۰-۹) digits → 0-9. Everything else is kept as is.
    static func normalizeDigits(_ text: String) -> String {
        String(text.map { char -> Character in
            guard let scalar = char.unicodeScalars.first, char.unicodeScalars.count == 1 else { return char }
            switch scalar.value {
            case 0x0660...0x0669: return Character(UnicodeScalar(scalar.value - 0x0660 + 0x30)!)
            case 0x06F0...0x06F9: return Character(UnicodeScalar(scalar.value - 0x06F0 + 0x30)!)
            default: return char
            }
        })
    }

    /// Checks one 14-digit candidate. Returns nil if it can't be a valid Egyptian national ID.
    static func info(for number: String) -> NationalIDInfo? {
        let digits = Array(number)
        guard digits.count == 14, digits.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }

        let century: Int
        switch digits[0] {
        case "2": century = 1900
        case "3": century = 2000
        default: return nil
        }
        guard let yy = Int(String(digits[1...2])),
              let mm = Int(String(digits[3...4])),
              let dd = Int(String(digits[5...6])) else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        let components = DateComponents(year: century + yy, month: mm, day: dd)
        guard let date = calendar.date(from: components),
              calendar.component(.month, from: date) == mm,     // rejects 31/02 etc.
              calendar.component(.day, from: date) == dd,
              date <= Date(),
              let oldest = calendar.date(byAdding: .year, value: -120, to: Date()), date >= oldest
        else { return nil }

        let governorateCode = String(digits[7...8])
        guard let governorate = governorates[governorateCode] else { return nil }

        return NationalIDInfo(number: number, birthDate: date, governorate: governorate)
    }

    /// Looks for a valid national ID inside a piece of recognized text.
    static func find(in text: String) -> NationalIDInfo? {
        let normalized = normalizeDigits(text)
        // Try as read, then with spaces removed (the camera sometimes splits the number).
        for variant in [normalized, normalized.filter { !$0.isWhitespace }] {
            for run in digitRuns(in: variant) where run.count == 14 {
                if let info = info(for: run) { return info }
                // Right-to-left text can come back reversed.
                if let info = info(for: String(run.reversed())) { return info }
            }
        }
        return nil
    }

    /// Maximal runs of ASCII digits, e.g. "abc 2950 x 12" → ["2950", "12"].
    private static func digitRuns(in text: String) -> [String] {
        text.split(whereSeparator: { !($0.isASCII && $0.isNumber) }).map(String.init)
    }
}
