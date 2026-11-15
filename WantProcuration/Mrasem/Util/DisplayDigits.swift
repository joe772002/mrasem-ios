//
//  DisplayDigits.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/util/DisplayDigits.kt
//  قرار 2026-11-15: كل الأرقام في الواجهة لاتينية (0-9) حتى والواجهة عربي.
//

import Foundation

extension String {
    /// يحوّل أي أرقام عربية-هندية (٠-٩) أو فارسية (۰-۹) إلى لاتينية (0-9). باقي الحروف كما هي.
    func toLatinDigits() -> String {
        String(String.UnicodeScalarView(unicodeScalars.map { scalar -> Unicode.Scalar in
            switch scalar.value {
            case 0x0660...0x0669: return Unicode.Scalar(scalar.value - 0x0660 + 0x30) ?? scalar
            case 0x06F0...0x06F9: return Unicode.Scalar(scalar.value - 0x06F0 + 0x30) ?? scalar
            case 0x066B: return "."
            default: return scalar
            }
        }))
    }
}

extension Int {
    func toLatinDigits() -> String {
        String(self)
    }
}

extension Double {
    /// رقم عشري للعرض: 3.5 ← «3.5»، و3.0 ← «3».
    func toLatinNumber() -> String {
        (self == floor(self) && !isInfinite) ? String(Int64(self)) : String(self)
    }
}
