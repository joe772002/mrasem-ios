//
//  MrasemType.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/theme/MrasemType.kt
//

import SwiftUI
import CoreText

/// أوزان خطوط مراسم.
enum MrasemFontWeight {
    case regular
    case medium
    case semiBold
    case bold
}

/// أسماء الـ PostScript الفعلية (من جدول `name` في ملفات TTF).
enum MrasemFonts {
    /// Reem Kufi — خط متغيّر (variable)، محور `wght` من 400 لـ 700.
    static let displayName = "ReemKufi"
    static let bodyRegular = "IBMPlexSansArabic-Regular"
    static let bodyMedium = "IBMPlexSansArabic-Medium"
    static let bodySemiBold = "IBMPlexSansArabic-SemiBold"
    static let bodyBold = "IBMPlexSansArabic-Bold"

    static func bodyPostScript(_ weight: MrasemFontWeight) -> String {
        switch weight {
        case .regular: return bodyRegular
        case .medium: return bodyMedium
        case .semiBold: return bodySemiBold
        case .bold: return bodyBold
        }
    }

    /// خط متغيّر بوزن محدد — SwiftUI مالهاش API مباشر لمحاور الخطوط المتغيّرة،
    /// فبنستخدم CoreText (محور `wght`).
    static func display(size: CGFloat, weight: CGFloat) -> Font {
        let base = CTFontCreateWithName(displayName as CFString, size, nil)
        let variation: [String: Any] = ["wght": weight]
        let attributes = [kCTFontVariationAttribute: variation as NSDictionary] as CFDictionary
        guard let descriptor = CTFontDescriptorCreateCopyWithAttributes(base, attributes) else {
            return .custom(displayName, size: size)
        }
        return Font(CTFontCreateWithFontDescriptor(descriptor, size, nil))
    }

    static func body(size: CGFloat, weight: MrasemFontWeight) -> Font {
        .custom(bodyPostScript(weight), size: size)
    }
}

/// نمط نص: الخط + ارتفاع السطر + تباعد الحروف.
///
/// SwiftUI مالهاش `lineHeight` جوه `Font`، فبنخزّن الأرقام الأصلية من التصميم
/// ونحسب `lineSpacing` و`tracking` منهم.
struct MrasemTextStyle {
    let font: Font
    let size: CGFloat
    let lineHeight: CGFloat?
    /// تباعد الحروف بوحدة em (0.08em مثلاً).
    let letterSpacingEm: CGFloat?

    var lineSpacing: CGFloat {
        guard let lineHeight else { return 0 }
        return max(0, lineHeight - size)
    }

    var tracking: CGFloat {
        (letterSpacingEm ?? 0) * size
    }

    static func display(
        size: CGFloat,
        weight: CGFloat,
        lineHeight: CGFloat? = nil,
        letterSpacingEm: CGFloat? = nil,
        scale: CGFloat = 1
    ) -> MrasemTextStyle {
        MrasemTextStyle(
            font: MrasemFonts.display(size: size * scale, weight: weight),
            size: size * scale,
            lineHeight: lineHeight.map { $0 * scale },
            letterSpacingEm: letterSpacingEm
        )
    }

    static func body(
        size: CGFloat,
        weight: MrasemFontWeight = .regular,
        lineHeight: CGFloat? = nil,
        letterSpacingEm: CGFloat? = nil,
        scale: CGFloat = 1
    ) -> MrasemTextStyle {
        MrasemTextStyle(
            font: MrasemFonts.body(size: size * scale, weight: weight),
            size: size * scale,
            lineHeight: lineHeight.map { $0 * scale },
            letterSpacingEm: letterSpacingEm
        )
    }
}

/// أنماط النص (01-DESIGN-SPEC §3). اللون يُحدَّد عند الاستخدام من MrasemColors.
struct MrasemTypography {
    let brandTitle: MrasemTextStyle
    let brandSub: MrasemTextStyle
    let heroDest: MrasemTextStyle
    let cardTitle: MrasemTextStyle
    let cardHeader: MrasemTextStyle
    let body: MrasemTextStyle
    let bodySm: MrasemTextStyle
    let label: MrasemTextStyle
    let chip: MrasemTextStyle
    let seg: MrasemTextStyle
    let roleSwitch: MrasemTextStyle
    let pill: MrasemTextStyle
    let statNumber: MrasemTextStyle
    let kpiNumber: MrasemTextStyle
    let caption: MrasemTextStyle
    let time: MrasemTextStyle
    let plateNumber: MrasemTextStyle
    let heroSub: MrasemTextStyle
    let button: MrasemTextStyle
    let plateCountry: MrasemTextStyle
    let avatarInitial: MrasemTextStyle
    let strong: MrasemTextStyle

    /// الأرقام بأرقام جدولية (tnum) — بديلها في SwiftUI هو `monospacedDigit()`.
    let hasTabularNumbers: Bool
}

extension MrasemTypography {
    /// الأنماط الأساسية. `scale` عامل تكبير Dynamic Type.
    static func standard(scale: CGFloat = 1) -> MrasemTypography {
        MrasemTypography(
            brandTitle: .display(size: 24, weight: 700, scale: scale),
            brandSub: .body(size: 11, weight: .medium, letterSpacingEm: 0.08, scale: scale),
            heroDest: .display(size: 26, weight: 700, lineHeight: 31, scale: scale),
            cardTitle: .body(size: 17, weight: .bold, lineHeight: 23, scale: scale),
            cardHeader: .body(size: 13, weight: .semiBold, scale: scale),
            body: .body(size: 15, lineHeight: 24, scale: scale),
            bodySm: .body(size: 14, lineHeight: 22, scale: scale),
            label: .body(size: 12, scale: scale),
            chip: .body(size: 13, scale: scale),
            seg: .body(size: 13, weight: .medium, scale: scale),
            roleSwitch: .body(size: 12, weight: .medium, scale: scale),
            pill: .body(size: 11, weight: .semiBold, scale: scale),
            statNumber: .body(size: 18, weight: .bold, scale: scale),
            kpiNumber: .body(size: 20, weight: .bold, scale: scale),
            caption: .body(size: 11, scale: scale),
            time: .body(size: 14, weight: .semiBold, scale: scale),
            plateNumber: .body(size: 18, weight: .bold, letterSpacingEm: 0.06, scale: scale),
            heroSub: .body(size: 13, scale: scale),
            button: .body(size: 14, weight: .medium, lineHeight: 22, scale: scale),
            plateCountry: .body(size: 9, weight: .bold, letterSpacingEm: 0.06, scale: scale),
            avatarInitial: .display(size: 18, weight: 500, scale: scale),
            strong: .body(size: 15, weight: .semiBold, scale: scale),
            hasTabularNumbers: true
        )
    }
}

extension View {
    /// يطبّق نمط نص مراسم (خط + ارتفاع سطر + تباعد حروف).
    func mrasemText(_ style: MrasemTextStyle, tabular: Bool = false) -> some View {
        self
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .tracking(style.tracking)
            .monospacedDigit(tabular)
    }
}

extension DynamicTypeSize {
    /// معامل تكبير Dynamic Type — مقياس موحّد لكل خطوط مراسم.
    var mrasemScale: CGFloat {
        switch self {
        case .xSmall: return 0.82
        case .small: return 0.88
        case .medium: return 0.94
        case .large: return 1.0
        case .xLarge: return 1.12
        case .xxLarge: return 1.24
        case .xxxLarge: return 1.35
        case .accessibility1: return 1.5
        case .accessibility2: return 1.7
        case .accessibility3: return 1.9
        case .accessibility4: return 2.1
        case .accessibility5: return 2.4
        @unknown default: return 1.0
        }
    }
}
