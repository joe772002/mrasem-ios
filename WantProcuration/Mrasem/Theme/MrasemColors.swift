//
//  MrasemColors.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/theme/MrasemColors.kt
//  Branch: main (source of truth — see docs/mrasem/02-RULES.md rule B1).
//

import SwiftUI

/// لون خام — بنحتفظ بقيمة RGB عشان نقدر نعمل الـ compositeOver زي Compose.
struct MrasemRGB: Equatable {
    let r: Double
    let g: Double
    let b: Double

    init(hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    func withAlpha(_ alpha: Double) -> Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// compositeOver: اللون ده بشفافية فوق لون معتم (زي `Color.compositeOver` في Compose).
    func over(_ bottom: MrasemRGB, _ alpha: Double) -> MrasemRGB {
        MrasemRGB(
            r: r * alpha + bottom.r * (1 - alpha),
            g: g * alpha + bottom.g * (1 - alpha),
            b: b * alpha + bottom.b * (1 - alpha)
        )
    }

    static let white = MrasemRGB(hex: 0xFFFFFF)
}

/// ألوان مراسم (01-DESIGN-SPEC §2). ممنوع استخدام لون من برّه هنا (قاعدة B2).
struct MrasemColors {
    let maroon: Color
    let maroonInk: Color
    let gold: Color
    let bg: Color
    let surface: Color
    let ink: Color
    let muted: Color
    let line: Color
    let tint: Color
    let ok: Color
    let warn: Color
    let headerBg: Color
    let onHeader: Color
    let isDark: Bool

    // ───── قيم محسوبة (زي الـ getters في Kotlin) ─────

    let pillOkBg: Color
    let pillWarnBg: Color
    let noticeBg: Color
    let noticeBorder: Color
    let timelineChangedBg: Color
    let segmentTrack: Color
    let segmentSelectedBg: Color
    let segmentSelectedText: Color
    let onMaroon: Color
    /// خلفية صف الخدمة (panel فاتح جوّه الكارت).
    let serviceRowBg: Color

    init(
        maroon: MrasemRGB,
        maroonInk: MrasemRGB,
        gold: MrasemRGB,
        bg: MrasemRGB,
        surface: MrasemRGB,
        ink: MrasemRGB,
        muted: MrasemRGB,
        line: MrasemRGB,
        tint: MrasemRGB,
        ok: MrasemRGB,
        warn: MrasemRGB,
        headerBg: MrasemRGB,
        onHeader: MrasemRGB,
        isDark: Bool
    ) {
        self.maroon = maroon.color
        self.maroonInk = maroonInk.color
        self.gold = gold.color
        self.bg = bg.color
        self.surface = surface.color
        self.ink = ink.color
        self.muted = muted.color
        self.line = line.color
        self.tint = tint.color
        self.ok = ok.color
        self.warn = warn.color
        self.headerBg = headerBg.color
        self.onHeader = onHeader.color
        self.isDark = isDark

        pillOkBg = ok.withAlpha(0.15)
        pillWarnBg = warn.withAlpha(0.16)
        noticeBg = gold.over(surface, 0.14).color
        noticeBorder = gold.withAlpha(0.45)
        timelineChangedBg = gold.withAlpha(0.12)
        segmentTrack = MrasemRGB.white.withAlpha(0.14)
        segmentSelectedBg = MrasemRGB.white.color
        segmentSelectedText = maroonInk.color
        onMaroon = MrasemRGB.white.color
        serviceRowBg = bg.color
    }
}

extension MrasemColors {
    static let light = MrasemColors(
        maroon: MrasemRGB(hex: 0x8A1538),
        maroonInk: MrasemRGB(hex: 0x6E0F2B),
        gold: MrasemRGB(hex: 0xB8862B),
        bg: MrasemRGB(hex: 0xF6F2EC),
        surface: MrasemRGB(hex: 0xFFFFFF),
        ink: MrasemRGB(hex: 0x24161B),
        muted: MrasemRGB(hex: 0x6F6266),
        line: MrasemRGB(hex: 0xE6DDD4),
        tint: MrasemRGB(hex: 0xF3E7EA),
        ok: MrasemRGB(hex: 0x2F7D4F),
        warn: MrasemRGB(hex: 0xB26A00),
        headerBg: MrasemRGB(hex: 0x8A1538),
        onHeader: .white,
        isDark: false
    )

    static let dark = MrasemColors(
        maroon: MrasemRGB(hex: 0xD0567A),
        maroonInk: MrasemRGB(hex: 0xE88AA6),
        gold: MrasemRGB(hex: 0xD9A649),
        bg: MrasemRGB(hex: 0x171114),
        surface: MrasemRGB(hex: 0x221A1D),
        ink: MrasemRGB(hex: 0xF3ECEE),
        muted: MrasemRGB(hex: 0xB3A5AA),
        line: MrasemRGB(hex: 0x3A2E33),
        tint: MrasemRGB(hex: 0x33202A),
        ok: MrasemRGB(hex: 0x5FBF86),
        warn: MrasemRGB(hex: 0xE0A040),
        headerBg: MrasemRGB(hex: 0x5A0F26),
        onHeader: .white,
        isDark: true
    )
}

/// ألوان ثابتة لا تتغير بين الفاتح والداكن (لوحات السيارات).
enum MrasemFixedColors {
    static let plateQaStrip = MrasemRGB(hex: 0x8A1538).color
    static let plateUkBg = MrasemRGB(hex: 0xF4D000).color
    static let plateUkStrip = MrasemRGB(hex: 0x1A3D8F).color
    static let plateText = MrasemRGB(hex: 0x111111).color
    static let plateBg = MrasemRGB.white.color
}
