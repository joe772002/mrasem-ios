//
//  MrasemFlowRoot.swift
//  Mrasem
//
//  Phase 13 — يوزّع بين سؤال البداية و«اختر المستخدم» والـ Shell حسب مرحلة التطبيق.
//

import SwiftUI
import Combine

struct MrasemFlowRoot: View {
    private let context: MrasemAppContext
    @ObservedObject private var flow: MrasemAppFlow
    /// مظهر التطبيق من الإعدادات (فاتح / داكن / حسب النظام).
    @State private var theme: ThemeChoice

    init(context: MrasemAppContext) {
        self.context = context
        self._theme = State(initialValue: context.backend.database.preferences.theme)
        self._flow = ObservedObject(wrappedValue: context.flow)
    }

    var body: some View {
        Group {
            switch flow.stage {
            case .chooseStart:
                StartChoiceScreen(context: context)
            case .pickUser:
                UserPickerScreen(context: context)
            case .main:
                MrasemShell(context: context)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: flow.stage)
        .mrasemTheme(theme.option)
        .preferredColorScheme(theme.colorScheme)
        .onReceive(context.backend.store.publisher.map(\.preferences.theme).removeDuplicates()) { theme = $0 }
    }
}

extension ThemeChoice {
    var option: MrasemThemeOption {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .system
        }
    }

    /// `nil` = يمشي مع النظام.
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
