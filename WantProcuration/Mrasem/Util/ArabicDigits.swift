//
//  ArabicDigits.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/util/ArabicDigits.kt
//

import Foundation

private let arabicDigits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]

extension String {
    /// يحوّل الأرقام اللاتينية (0-9) إلى أرقام عربية-هندية (٠-٩). باقي الحروف كما هي.
    func toArabicDigits() -> String {
        String(map { ch -> Character in
            if ch.isASCII, let value = ch.wholeNumberValue, value >= 0, value <= 9 {
                return arabicDigits[value]
            }
            return ch
        })
    }
}

extension Int {
    func toArabicDigits() -> String {
        String(self).toArabicDigits()
    }
}

extension Double {
    /// رقم عشري للعرض: 3.5 ← «٣.٥»، و3.0 ← «٣» (زي `ar(n)` في المصدر).
    func toArabicNumber() -> String {
        let text = (self == floor(self) && !isInfinite) ? String(Int64(self)) : String(self)
        return text.toArabicDigits()
    }
}
