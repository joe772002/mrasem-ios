//
//  MrasemIllustrations.swift
//  Mrasem
//
//  Phase 18 — من MrasemDrawings (B8): رمز الـ QR ورسمة الزي. الألوان الثابتة من التصميم الأصلي (استثناء مسجّل في 02-RULES).
//

import SwiftUI

// ───────────────────────── QR ─────────────────────────

private let qrCells: [(Int, Int)] = [
    (0, 0), (1, 0), (2, 0), (4, 0), (7, 0), (8, 0), (9, 0), (10, 0),
    (0, 1), (2, 1), (3, 1), (6, 1), (8, 1), (10, 1),
    (0, 2), (1, 2), (2, 2), (3, 2), (6, 2), (8, 2), (9, 2), (10, 2),
    (0, 3), (1, 3), (5, 3), (8, 3),
    (4, 4), (6, 4), (9, 4),
    (0, 5), (7, 5),
    (2, 6), (4, 6), (6, 6), (8, 6),
    (8, 7), (9, 7), (10, 7),
    (0, 8), (1, 8), (2, 8), (4, 8),
    (0, 9), (1, 9), (2, 9), (7, 9), (8, 9), (9, 9), (10, 9),
    (0, 10), (1, 10), (2, 10), (4, 10), (5, 10), (6, 10),
]

/// رمز QR توضيحي (11×11) — خلفية بيضاء ثابتة في الفاتح والداكن.
struct MrasemQrPlaceholder: View {
    var size: CGFloat = 84

    var body: some View {
        Canvas { context, canvasSize in
            let u = canvasSize.width / 72

            context.fill(
                Path(CGRect(origin: .zero, size: canvasSize)),
                with: .color(.white)
            )

            for cell in qrCells {
                let rect = CGRect(
                    x: CGFloat(cell.0) * 6 * u + 3 * u,
                    y: CGFloat(cell.1) * 6 * u + 3 * u,
                    width: 6 * u,
                    height: 6 * u
                )
                context.fill(
                    Path(rect),
                    with: .color(Color(.sRGB, red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255))
                )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// ───────────────────────── Dress ─────────────────────────

enum DressKind {
    case formal
    case bisht
}

/// رسم الزي المعتمد (96×120).
struct MrasemDressIllustration: View {
    let kind: DressKind
    var width: CGFloat = 96
    var height: CGFloat = 120

    init(kind: DressKind, width: CGFloat = 96, height: CGFloat = 120) {
        self.kind = kind
        self.width = width
        self.height = height
    }

    var body: some View {
        Canvas { context, size in
            let k = size.width / 96
            let skin = Color(.sRGB, red: 0xD9 / 255, green: 0xB9 / 255, blue: 0x9B / 255)
            let navy = Color(.sRGB, red: 0x1F / 255, green: 0x2A / 255, blue: 0x44 / 255)
            let gold = Color(.sRGB, red: 0xC9 / 255, green: 0xA1 / 255, blue: 0x4A / 255)
            let black = Color(.sRGB, red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
            let offWhite = Color(.sRGB, red: 0xF7 / 255, green: 0xF7 / 255, blue: 0xF5 / 255)
            let lightGray = Color(.sRGB, red: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255)
            let midGray = Color(.sRGB, red: 0xBB / 255, green: 0xBB / 255, blue: 0xBB / 255)
            let darkBrown = Color(.sRGB, red: 0x2A / 255, green: 0x1F / 255, blue: 0x1A / 255)
            let maroon = Color(.sRGB, red: 0x8A / 255, green: 0x15 / 255, blue: 0x38 / 255)

            if kind == .bisht {
                context.fill(
                    Path(ellipseIn: CGRect(x: 37 * k, y: 9 * k, width: 22 * k, height: 22 * k)),
                    with: .color(skin)
                )

                // الغترة.
                var ghutra = Path()
                ghutra.move(to: CGPoint(x: 33 * k, y: 16 * k))
                ghutra.addQuadCurve(
                    to: CGPoint(x: 63 * k, y: 16 * k),
                    control: CGPoint(x: 48 * k, y: 2 * k)
                )
                ghutra.addLine(to: CGPoint(x: 66 * k, y: 30 * k))
                ghutra.addQuadCurve(
                    to: CGPoint(x: 30 * k, y: 30 * k),
                    control: CGPoint(x: 48 * k, y: 24 * k)
                )
                ghutra.closeSubpath()
                context.fill(ghutra, with: .color(.white))
                context.stroke(ghutra, with: .color(midGray), lineWidth: 1)

                // البشت.
                var bisht = Path()
                bisht.move(to: CGPoint(x: 28 * k, y: 36 * k))
                bisht.addLine(to: CGPoint(x: 48 * k, y: 32 * k))
                bisht.addLine(to: CGPoint(x: 68 * k, y: 36 * k))
                bisht.addLine(to: CGPoint(x: 72 * k, y: 116 * k))
                bisht.addLine(to: CGPoint(x: 24 * k, y: 116 * k))
                bisht.closeSubpath()
                context.fill(bisht, with: .color(offWhite))
                context.stroke(bisht, with: .color(lightGray), lineWidth: 1)

                // الأكمام.
                var sleeves = Path()
                sleeves.move(to: CGPoint(x: 22 * k, y: 38 * k))
                sleeves.addLine(to: CGPoint(x: 40 * k, y: 34 * k))
                sleeves.addLine(to: CGPoint(x: 44 * k, y: 116 * k))
                sleeves.addLine(to: CGPoint(x: 16 * k, y: 116 * k))
                sleeves.closeSubpath()

                sleeves.move(to: CGPoint(x: 74 * k, y: 38 * k))
                sleeves.addLine(to: CGPoint(x: 56 * k, y: 34 * k))
                sleeves.addLine(to: CGPoint(x: 52 * k, y: 116 * k))
                sleeves.addLine(to: CGPoint(x: 80 * k, y: 116 * k))
                sleeves.closeSubpath()
                context.fill(sleeves, with: .color(darkBrown))

                // الحزام الذهبي.
                var belt = Path()
                belt.move(to: CGPoint(x: 40 * k, y: 34 * k))
                belt.addLine(to: CGPoint(x: 44 * k, y: 116 * k))
                belt.move(to: CGPoint(x: 56 * k, y: 34 * k))
                belt.addLine(to: CGPoint(x: 52 * k, y: 116 * k))
                context.stroke(belt, with: .color(gold), lineWidth: 2.5 * k)
            } else {
                context.fill(
                    Path(ellipseIn: CGRect(x: 37 * k, y: 7 * k, width: 22 * k, height: 22 * k)),
                    with: .color(skin)
                )

                // الجاكيت.
                var jacket = Path()
                jacket.move(to: CGPoint(x: 26 * k, y: 36 * k))
                jacket.addLine(to: CGPoint(x: 48 * k, y: 30 * k))
                jacket.addLine(to: CGPoint(x: 70 * k, y: 36 * k))
                jacket.addLine(to: CGPoint(x: 74 * k, y: 80 * k))
                jacket.addLine(to: CGPoint(x: 22 * k, y: 80 * k))
                jacket.closeSubpath()
                context.fill(jacket, with: .color(navy))

                // القميص.
                var shirt = Path()
                shirt.move(to: CGPoint(x: 42 * k, y: 31 * k))
                shirt.addLine(to: CGPoint(x: 48 * k, y: 46 * k))
                shirt.addLine(to: CGPoint(x: 54 * k, y: 31 * k))
                shirt.closeSubpath()
                context.fill(shirt, with: .color(.white))

                // العنّابة.
                var tie = Path()
                tie.move(to: CGPoint(x: 46 * k, y: 36 * k))
                tie.addLine(to: CGPoint(x: 50 * k, y: 36 * k))
                tie.addLine(to: CGPoint(x: 52 * k, y: 66 * k))
                tie.addLine(to: CGPoint(x: 48 * k, y: 72 * k))
                tie.addLine(to: CGPoint(x: 44 * k, y: 66 * k))
                tie.closeSubpath()
                context.fill(tie, with: .color(maroon))

                // البنطال.
                context.fill(
                    Path(CGRect(x: 30 * k, y: 80 * k, width: 15 * k, height: 34 * k)),
                    with: .color(navy)
                )
                context.fill(
                    Path(CGRect(x: 51 * k, y: 80 * k, width: 15 * k, height: 34 * k)),
                    with: .color(navy)
                )

                // الحذاء.
                context.fill(
                    Path(roundedRect: CGRect(x: 28 * k, y: 112 * k, width: 18 * k, height: 6 * k), cornerRadius: 2 * k),
                    with: .color(black)
                )
                context.fill(
                    Path(roundedRect: CGRect(x: 50 * k, y: 112 * k, width: 18 * k, height: 6 * k), cornerRadius: 2 * k),
                    with: .color(black)
                )
            }
        }
        .frame(width: width, height: height)
    }
}
