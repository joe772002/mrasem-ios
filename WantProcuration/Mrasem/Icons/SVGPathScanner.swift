//
//  SVGPathScanner.swift
//  Mrasem
//
//  Phase 18 — من SVGPath (B8): قارئ نص مسار SVG حرف بحرف.
//

import SwiftUI

/// قارئ بسيط لمسار SVG: بيفصل الأرقام عن الأوامر.
struct SVGPathScanner {
    let chars: [Character]
    private(set) var index: Int = 0

    init(chars: [Character]) {
        self.chars = chars
    }

    mutating func skipSeparators() {
        while index < chars.count {
            let ch = chars[index]
            if ch == " " || ch == "\n" || ch == "\r" || ch == "\t" || ch == "," {
                index += 1
            } else {
                break
            }
        }
    }

    mutating func readCommand() -> Character? {
        skipSeparators()
        guard index < chars.count else { return nil }
        let ch = chars[index]
        guard ch.isLetter else { return nil }
        index += 1
        return ch
    }

    mutating func readNumber() -> Double? {
        skipSeparators()
        let start = index
        var text = ""

        if index < chars.count, chars[index] == "-" || chars[index] == "+" {
            text.append(chars[index])
            index += 1
        }

        var sawDigit = false
        while index < chars.count, chars[index].isNumber {
            text.append(chars[index])
            index += 1
            sawDigit = true
        }

        if index < chars.count, chars[index] == "." {
            text.append(chars[index])
            index += 1
            while index < chars.count, chars[index].isNumber {
                text.append(chars[index])
                index += 1
                sawDigit = true
            }
        }

        guard sawDigit else {
            index = start
            return nil
        }

        if index < chars.count, chars[index] == "e" || chars[index] == "E" {
            let exponentStart = index
            var exponent = String(chars[index])
            index += 1
            if index < chars.count, chars[index] == "-" || chars[index] == "+" {
                exponent.append(chars[index])
                index += 1
            }
            var sawExponentDigit = false
            while index < chars.count, chars[index].isNumber {
                exponent.append(chars[index])
                index += 1
                sawExponentDigit = true
            }
            if !sawExponentDigit {
                index = exponentStart
            } else {
                text += exponent
            }
        }

        return Double(text)
    }

    /// flags القوس (0/1) — ممكن تكون ملزوقة من غير فاصل.
    mutating func readFlag() -> Bool? {
        skipSeparators()
        guard index < chars.count else { return nil }
        switch chars[index] {
        case "0":
            index += 1
            return false
        case "1":
            index += 1
            return true
        default:
            return nil
        }
    }
}
