//
//  MrasemShapes.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/theme/MrasemShapes.kt
//

import SwiftUI

/// الأشكال (01-DESIGN-SPEC §4) — قيم الـ corner radius بالنقطة (dp = pt).
struct MrasemShapes {
    let card: CGFloat
    let hero: CGFloat
    let stat: CGFloat
    let kpi: CGFloat
    let button: CGFloat
    let pill: CGFloat
    let chip: CGFloat
    let dayButton: CGFloat
    let serviceLogo: CGFloat
    let serviceRow: CGFloat
    let place: CGFloat
    let map: CGFloat
    let notice: CGFloat
    let toast: CGFloat
    let bubble: CGFloat
    let field: CGFloat
    let segmentButton: CGFloat
    let plate: CGFloat

    static let standard = MrasemShapes(
        card: 14,
        hero: 16,
        stat: 10,
        kpi: 12,
        button: 10,
        pill: 99,
        chip: 99,
        dayButton: 10,
        serviceLogo: 10,
        serviceRow: 12,
        place: 12,
        map: 10,
        notice: 12,
        toast: 12,
        bubble: 14,
        field: 10,
        segmentButton: 8,
        plate: 6
    )
}

extension MrasemShapes {
    /// فقاعة رد المساعد: الركن المواجه (start-start) 4.
    func bubbleBot() -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 4,
            bottomLeadingRadius: bubble,
            bottomTrailingRadius: bubble,
            topTrailingRadius: bubble
        )
    }

    /// فقاعة رسالة المستخدم: الركن المواجه (start-end) 4.
    func bubbleMe() -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: bubble,
            bottomLeadingRadius: bubble,
            bottomTrailingRadius: bubble,
            topTrailingRadius: 4
        )
    }
}

/// المسافات والأبعاد.
struct MrasemDimens {
    let cardPadding: CGFloat
    let cardGap: CGFloat
    let heroPadding: CGFloat
    let heroGap: CGFloat
    let heroTopBorder: CGFloat
    let screenHorizontal: CGFloat
    let screenTop: CGFloat
    let screenBottom: CGFloat
    let screenGap: CGFloat
    let avatar: CGFloat
    let serviceLogo: CGFloat
    let bottomBarIcon: CGFloat
    let minTouch: CGFloat
    let borderWidth: CGFloat

    static let standard = MrasemDimens(
        cardPadding: 14,
        cardGap: 10,
        heroPadding: 16,
        heroGap: 12,
        heroTopBorder: 4,
        screenHorizontal: 16,
        screenTop: 16,
        screenBottom: 96,
        screenGap: 14,
        avatar: 46,
        serviceLogo: 40,
        bottomBarIcon: 22,
        minTouch: 48,
        borderWidth: 1
    )
}
