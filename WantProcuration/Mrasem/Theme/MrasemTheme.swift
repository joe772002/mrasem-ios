//
//  MrasemTheme.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/theme/MrasemTheme.kt
//
//  Thيم مراسم: dynamicColor مقفول (قاعدة B4) — الألوان من `MrasemColors` في الكود.
//

import SwiftUI

/// خيار الثيم.
enum MrasemThemeOption {
    case light
    case dark
    case system
}

/// كل قيم مراسم في مكان واحد — بيتحقن في الـ environment عن طريق `\.mrasem`.
struct MrasemThemeValue {
    let colors: MrasemColors
    let type: MrasemTypography
    let shapes: MrasemShapes
    let dimens: MrasemDimens
}

private struct MrasemThemeKey: EnvironmentKey {
    static let defaultValue = MrasemThemeValue(
        colors: .light,
        type: .standard(),
        shapes: .standard,
        dimens: .standard
    )
}

extension EnvironmentValues {
    /// الوصول السريع للثيم: `@Environment(\.mrasem)`.
    var mrasem: MrasemThemeValue {
        get { self[MrasemThemeKey.self] }
        set { self[MrasemThemeKey.self] = newValue }
    }
}

extension View {
    /// يطبّق ثيم مراسم (فاتح / داكن / حسب النظام).
    func mrasemTheme(_ option: MrasemThemeOption = .system) -> some View {
        modifier(MrasemThemeModifier(option: option))
    }
}

struct MrasemThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let option: MrasemThemeOption

    func body(content: Content) -> some View {
        let isDark: Bool = {
            switch option {
            case .light: return false
            case .dark: return true
            case .system: return colorScheme == .dark
            }
        }()

        let value = MrasemThemeValue(
            colors: isDark ? .dark : .light,
            type: .standard(scale: dynamicTypeSize.mrasemScale),
            shapes: .standard,
            dimens: .standard
        )

        return content.environment(\.mrasem, value)
    }
}

/// وصول مختصر زي `Mrasem.colors` في Android.
extension EnvironmentValues {
    var mrasemColors: MrasemColors { mrasem.colors }
    var mrasemType: MrasemTypography { mrasem.type }
    var mrasemShapes: MrasemShapes { mrasem.shapes }
    var mrasemDimens: MrasemDimens { mrasem.dimens }
}
