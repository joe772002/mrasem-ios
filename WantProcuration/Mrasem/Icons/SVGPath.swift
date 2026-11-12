//
//  SVGPath.swift
//  Mrasem
//
//  محوّل مسارات SVG (24×24) لـ `Path` بتاع SwiftUI.
//  الأوامر المدعومة: M m L l H h V v C c S s Q q T t A a Z z
//

import SwiftUI

enum SVGPath {
    /// يحوّل مسار SVG لنقطة مرجعية 24×24 لـ `Path`.
    static func parse(_ d: String) -> Path {
        var path = Path()
        var scanner = Scanner(chars: Array(d))

        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControl: CGPoint?
        var lastQuadControl: CGPoint?

        func move(to point: CGPoint) {
            path.move(to: point)
            current = point
            subpathStart = point
            lastCubicControl = nil
            lastQuadControl = nil
        }

        func line(to point: CGPoint) {
            path.addLine(to: point)
            current = point
            lastCubicControl = nil
            lastQuadControl = nil
        }

        func cubic(to point: CGPoint, control1: CGPoint, control2: CGPoint) {
            path.addCurve(to: point, control1: control1, control2: control2)
            current = point
            lastCubicControl = control2
            lastQuadControl = nil
        }

        func quad(to point: CGPoint, control: CGPoint) {
            path.addQuadCurve(to: point, control: control)
            current = point
            lastQuadControl = control
            lastCubicControl = nil
        }

        func close() {
            path.closeSubpath()
            current = subpathStart
            lastCubicControl = nil
            lastQuadControl = nil
        }

        while true {
            scanner.skipSeparators()
            guard let command = scanner.readCommand() else { break }

            let relative = command.isLowercase
            let upper = Character(String(command).uppercased())

            switch upper {
            case "Z":
                close()
                continue

            case "M":
                scanner.skipSeparators()
                guard let x = scanner.readNumber(), let y = scanner.readNumber() else { return path }
                let point = relative
                    ? CGPoint(x: current.x + x, y: current.y + y)
                    : CGPoint(x: x, y: y)
                move(to: point)
                // أول pair بعد M معناها move، والباقي خطوط.
                while true {
                    scanner.skipSeparators()
                    guard let nx = scanner.readNumber(), let ny = scanner.readNumber() else { break }
                    let next = relative
                        ? CGPoint(x: current.x + nx, y: current.y + ny)
                        : CGPoint(x: nx, y: ny)
                    line(to: next)
                }

            case "L":
                while true {
                    scanner.skipSeparators()
                    guard let x = scanner.readNumber(), let y = scanner.readNumber() else { break }
                    let point = relative
                        ? CGPoint(x: current.x + x, y: current.y + y)
                        : CGPoint(x: x, y: y)
                    line(to: point)
                }

            case "H":
                while true {
                    scanner.skipSeparators()
                    guard let x = scanner.readNumber() else { break }
                    line(to: CGPoint(x: relative ? current.x + x : x, y: current.y))
                }

            case "V":
                while true {
                    scanner.skipSeparators()
                    guard let y = scanner.readNumber() else { break }
                    line(to: CGPoint(x: current.x, y: relative ? current.y + y : y))
                }

            case "C":
                while true {
                    scanner.skipSeparators()
                    guard let x1 = scanner.readNumber(), let y1 = scanner.readNumber(),
                          let x2 = scanner.readNumber(), let y2 = scanner.readNumber(),
                          let x = scanner.readNumber(), let y = scanner.readNumber()
                    else { break }
                    let c1 = relative
                        ? CGPoint(x: current.x + x1, y: current.y + y1)
                        : CGPoint(x: x1, y: y1)
                    let c2 = relative
                        ? CGPoint(x: current.x + x2, y: current.y + y2)
                        : CGPoint(x: x2, y: y2)
                    let end = relative
                        ? CGPoint(x: current.x + x, y: current.y + y)
                        : CGPoint(x: x, y: y)
                    cubic(to: end, control1: c1, control2: c2)
                }

            case "S":
                while true {
                    scanner.skipSeparators()
                    guard let x2 = scanner.readNumber(), let y2 = scanner.readNumber(),
                          let x = scanner.readNumber(), let y = scanner.readNumber()
                    else { break }
                    let c1 = reflected(lastCubicControl, from: current)
                    let c2 = relative
                        ? CGPoint(x: current.x + x2, y: current.y + y2)
                        : CGPoint(x: x2, y: y2)
                    let end = relative
                        ? CGPoint(x: current.x + x, y: current.y + y)
                        : CGPoint(x: x, y: y)
                    cubic(to: end, control1: c1, control2: c2)
                }

            case "Q":
                while true {
                    scanner.skipSeparators()
                    guard let x1 = scanner.readNumber(), let y1 = scanner.readNumber(),
                          let x = scanner.readNumber(), let y = scanner.readNumber()
                    else { break }
                    let control = relative
                        ? CGPoint(x: current.x + x1, y: current.y + y1)
                        : CGPoint(x: x1, y: y1)
                    let end = relative
                        ? CGPoint(x: current.x + x, y: current.y + y)
                        : CGPoint(x: x, y: y)
                    quad(to: end, control: control)
                }

            case "T":
                while true {
                    scanner.skipSeparators()
                    guard let x = scanner.readNumber(), let y = scanner.readNumber() else { break }
                    let control = reflected(lastQuadControl, from: current)
                    let end = relative
                        ? CGPoint(x: current.x + x, y: current.y + y)
                        : CGPoint(x: x, y: y)
                    quad(to: end, control: control)
                }

            case "A":
                while true {
                    scanner.skipSeparators()
                    guard let rx = scanner.readNumber(),
                          let ry = scanner.readNumber(),
                          let rotation = scanner.readNumber(),
                          let largeArc = scanner.readFlag(),
                          let sweep = scanner.readFlag(),
                          let x = scanner.readNumber(),
                          let y = scanner.readNumber()
                    else { break }
                    let end = relative
                        ? CGPoint(x: current.x + x, y: current.y + y)
                        : CGPoint(x: x, y: y)
                    addArc(
                        to: &path,
                        from: current,
                        rx: rx,
                        ry: ry,
                        xAxisRotation: rotation,
                        largeArc: largeArc,
                        sweep: sweep,
                        to: end
                    )
                    current = end
                    lastCubicControl = nil
                    lastQuadControl = nil
                }

            default:
                // أمر غير معروف: نتخطاه.
                continue
            }
        }

        return path
    }

    /// انعكاس نقطة التحكم السابقة (S / T).
    private static func reflected(_ control: CGPoint?, from current: CGPoint) -> CGPoint {
        guard let control else { return current }
        return CGPoint(x: 2 * current.x - control.x, y: 2 * current.y - control.y)
    }

    /// يضيف قوس SVG كمنحنيات بيزييه (SwiftUI مالهاش arcs).
    private static func addArc(
        to path: inout Path,
        from: CGPoint,
        rx: Double,
        ry: Double,
        xAxisRotation: Double,
        largeArc: Bool,
        sweep: Bool,
        to end: CGPoint
    ) {
        if rx == 0 || ry == 0 {
            path.addLine(to: end)
            return
        }

        var radiusX = abs(rx)
        var radiusY = abs(ry)

        let phi = xAxisRotation * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        let dx2 = (from.x - end.x) / 2
        let dy2 = (from.y - end.y) / 2
        let x1p = cosPhi * dx2 + sinPhi * dy2
        let y1p = -sinPhi * dx2 + cosPhi * dy2

        // تصحيح نصف القطر لو كان صغير على المسافة (spec SVG §F.6.6).
        let lambda = (x1p * x1p) / (radiusX * radiusX) + (y1p * y1p) / (radiusY * radiusY)
        if lambda > 1 {
            let scale = lambda.squareRoot()
            radiusX *= scale
            radiusY *= scale
        }

        let sign: Double = (largeArc != sweep) ? 1 : -1
        let numerator = radiusX * radiusX * radiusY * radiusY
            - radiusX * radiusX * y1p * y1p
            - radiusY * radiusY * x1p * x1p
        let denominator = radiusX * radiusX * y1p * y1p + radiusY * radiusY * x1p * x1p
        let coefficient = sign * (max(0, numerator / denominator)).squareRoot()

        let cxp = coefficient * radiusX * y1p / radiusY
        let cyp = -coefficient * radiusY * x1p / radiusX
        let cx = cosPhi * cxp - sinPhi * cyp + (from.x + end.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (from.y + end.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let dot = ux * vx + uy * vy
            let lengths = ((ux * ux + uy * uy) * (vx * vx + vy * vy)).squareRoot()
            var value = acos(max(-1, min(1, dot / lengths)))
            if ux * vy - uy * vx < 0 { value = -value }
            return value
        }

        let ux = (x1p - cxp) / radiusX
        let uy = (y1p - cyp) / radiusY
        let vx = (-x1p - cxp) / radiusX
        let vy = (-y1p - cyp) / radiusY

        let theta1 = angle(1, 0, ux, uy)
        var delta = angle(ux, uy, vx, vy)
        if !sweep && delta > 0 {
            delta -= 2 * .pi
        } else if sweep && delta < 0 {
            delta += 2 * .pi
        }

        let segments = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let step = delta / Double(segments)
        let t = 4.0 / 3.0 * tan(step / 4)

        func point(_ ct: Double, _ st: Double) -> CGPoint {
            CGPoint(
                x: cx + radiusX * cosPhi * ct - radiusY * sinPhi * st,
                y: cy + radiusX * sinPhi * ct + radiusY * cosPhi * st
            )
        }

        func derivative(_ ct: Double, _ st: Double) -> CGPoint {
            CGPoint(
                x: -radiusX * cosPhi * st - radiusY * sinPhi * ct,
                y: -radiusX * sinPhi * st + radiusY * cosPhi * ct
            )
        }

        var theta = theta1
        for _ in 0 ..< segments {
            let cosT1 = cos(theta)
            let sinT1 = sin(theta)
            let theta2 = theta + step
            let cosT2 = cos(theta2)
            let sinT2 = sin(theta2)

            let p1 = point(cosT1, sinT1)
            let p2 = point(cosT2, sinT2)
            let d1 = derivative(cosT1, sinT1)
            let d2 = derivative(cosT2, sinT2)

            let c1 = CGPoint(x: p1.x + t * d1.x, y: p1.y + t * d1.y)
            let c2 = CGPoint(x: p2.x - t * d2.x, y: p2.y - t * d2.y)

            path.addCurve(to: p2, control1: c1, control2: c2)
            theta = theta2
        }
    }
}

/// قارئ بسيط لمسار SVG: بيفصل الأرقام عن الأوامر.
private struct Scanner {
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
