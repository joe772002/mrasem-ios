//
//  MrasemDrawings.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemDrawings.kt
//
//  الرسومات متعمدة تبقى بالألوان الثابتة من التصميم الأصلي (استثناء مسجّل في 02-RULES).
//

import SwiftUI

// ───────────────────────── Map ─────────────────────────

/// معاينة الخريطة (400×150) — مرسومة بالكود كما في التصميم.
struct MrasemMapPreview: View {
    @Environment(\.mrasem) private var theme

    let venueLabel: String
    let hotelLabel: String

    init(venueLabel: String, hotelLabel: String) {
        self.venueLabel = venueLabel
        self.hotelLabel = hotelLabel
    }

    var body: some View {
        let c = theme.colors
        let water = Color(.sRGB, red: 0x3B / 255, green: 0x82 / 255, blue: 0xC4 / 255).opacity(0.22)

        GeometryReader { geo in
            let k = geo.size.width / 400

            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    let k = size.width / 400

                    // الأرضية.
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(c.tint)
                    )

                    // الماء.
                    var waterPath = Path()
                    waterPath.move(to: CGPoint(x: 0, y: 110 * k))
                    waterPath.addQuadCurve(
                        to: CGPoint(x: 200 * k, y: 105 * k),
                        control: CGPoint(x: 120 * k, y: 90 * k)
                    )
                    waterPath.addQuadCurve(
                        to: CGPoint(x: 400 * k, y: 95 * k),
                        control: CGPoint(x: 300 * k, y: 120 * k)
                    )
                    waterPath.addLine(to: CGPoint(x: 400 * k, y: 150 * k))
                    waterPath.addLine(to: CGPoint(x: 0, y: 150 * k))
                    waterPath.closeSubpath()
                    context.fill(waterPath, with: .color(water))

                    // الطرق.
                    var roads = Path()
                    roads.move(to: CGPoint(x: 30 * k, y: 0))
                    roads.addLine(to: CGPoint(x: 30 * k, y: 150 * k))
                    roads.move(to: CGPoint(x: 0, y: 50 * k))
                    roads.addLine(to: CGPoint(x: 400 * k, y: 50 * k))
                    roads.move(to: CGPoint(x: 150 * k, y: 0))
                    roads.addLine(to: CGPoint(x: 210 * k, y: 150 * k))
                    roads.move(to: CGPoint(x: 320 * k, y: 0))
                    roads.addLine(to: CGPoint(x: 320 * k, y: 110 * k))
                    context.stroke(roads, with: .color(c.line), lineWidth: 8 * k)

                    // مسار الوصول.
                    var route = Path()
                    route.move(to: CGPoint(x: 100 * k, y: 76 * k))
                    route.addCurve(
                        to: CGPoint(x: 236 * k, y: 46 * k),
                        control1: CGPoint(x: 160 * k, y: 70 * k),
                        control2: CGPoint(x: 200 * k, y: 50 * k)
                    )
                    context.stroke(
                        route,
                        with: .color(c.gold),
                        style: StrokeStyle(lineWidth: 2.5 * k, dash: [6 * k, 5 * k])
                    )

                    // الفندق.
                    let hotelRect = CGRect(x: 60 * k, y: 62 * k, width: 40 * k, height: 30 * k)
                    context.fill(Path(roundedRect: hotelRect, cornerRadius: 4 * k), with: .color(c.surface))
                    context.stroke(
                        Path(roundedRect: hotelRect, cornerRadius: 4 * k),
                        with: .color(c.gold),
                        lineWidth: 2 * k
                    )

                    // المكان.
                    let venueRect = CGRect(x: 235 * k, y: 22 * k, width: 56 * k, height: 44 * k)
                    context.fill(Path(roundedRect: venueRect, cornerRadius: 4 * k), with: .color(c.surface))
                    context.stroke(
                        Path(roundedRect: venueRect, cornerRadius: 4 * k),
                        with: .color(c.maroon),
                        lineWidth: 2 * k
                    )

                    // دبوس المكان.
                    var pin = Path()
                    pin.move(to: CGPoint(x: 262 * k, y: 18 * k))
                    pin.addCurve(
                        to: CGPoint(x: 247 * k, y: 32 * k),
                        control1: CGPoint(x: 253 * k, y: 18 * k),
                        control2: CGPoint(x: 247 * k, y: 24 * k)
                    )
                    pin.addCurve(
                        to: CGPoint(x: 262 * k, y: 54 * k),
                        control1: CGPoint(x: 247 * k, y: 42 * k),
                        control2: CGPoint(x: 262 * k, y: 54 * k)
                    )
                    pin.addCurve(
                        to: CGPoint(x: 277 * k, y: 32 * k),
                        control1: CGPoint(x: 262 * k, y: 54 * k),
                        control2: CGPoint(x: 277 * k, y: 42 * k)
                    )
                    pin.addCurve(
                        to: CGPoint(x: 262 * k, y: 18 * k),
                        control1: CGPoint(x: 277 * k, y: 24 * k),
                        control2: CGPoint(x: 271 * k, y: 18 * k)
                    )
                    pin.closeSubpath()
                    context.fill(pin, with: .color(c.maroon))

                    context.fill(
                        Path(ellipseIn: CGRect(x: 257 * k, y: 13 * k, width: 10 * k, height: 10 * k)),
                        with: .color(.white)
                    )
                }

                // النصوص — من فوق الـ canvas عشان تفضل حادة.
                Text(venueLabel)
                    .font(MrasemFonts.body(size: 11, weight: .regular))
                    .foregroundColor(c.maroon)
                    .position(x: 263 * k, y: 49 * k)

                Text(hotelLabel)
                    .font(MrasemFonts.body(size: 10, weight: .regular))
                    .foregroundColor(c.gold)
                    .position(x: 80 * k, y: 77 * k)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.map))
            .overlay(
                RoundedRectangle(cornerRadius: theme.shapes.map)
                    .stroke(c.line, lineWidth: theme.dimens.borderWidth)
            )
        }
        .aspectRatio(400.0 / 150.0, contentMode: .fit)
    }
}
