//
//  ArabicSearchNormalizer.swift
//  WantProcuration
//
//  Text normalization used for FAQ search and keyword matching (IOS_PORT_GUIDE.md §4.2):
//  lowercase, remove diacritics and tatweel, أ/إ/آ → ا, ة → ه, ى → ي.
//

import Foundation

enum ArabicSearchNormalizer {
    static func normalize(_ text: String) -> String {
        var result = ""
        for scalar in text.lowercased().unicodeScalars {
            switch scalar.value {
            case 0x064B...0x0652, 0x0640: continue            // tashkeel [ً-ْ] and tatweel ـ
            case 0x0623, 0x0625, 0x0622: result.append("ا")    // أ إ آ
            case 0x0629: result.append("ه")                    // ة
            case 0x0649: result.append("ي")                    // ى
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    /// Converts Arabic-Indic (٠-٩) and Persian (۰-۹) digits to 0-9 and keeps digits only.
    static func digitsOnly(_ text: String) -> String {
        NationalIDParser.normalizeDigits(text).filter { $0.isASCII && $0.isNumber }
    }
}
