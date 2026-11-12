//
//  MrasemBrand.swift
//  Mrasem
//
//  Temporary brand colors for Phase 0 (splash, root background, placeholder).
//  Values come from 01-DESIGN-SPEC.md. Phase 1 replaces this with the full
//  MrasemColors token set (Light/Dark) and deletes this file.
//

import SwiftUI

enum MrasemBrand {
    /// maroon (Light) — also the Light header background.
    static let maroon = Color(hex: "8A1538")

    /// headerBg (Dark).
    static let headerDark = Color(hex: "5A0F26")

    /// gold (Light) — status/highlight only.
    static let gold = Color(hex: "B8862B")

    /// Header text is always white.
    static let onHeader = Color.white
}
