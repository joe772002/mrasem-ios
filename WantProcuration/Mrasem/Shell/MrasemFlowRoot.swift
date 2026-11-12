//
//  MrasemFlowRoot.swift
//  Mrasem
//
//  Phase 13 — يوزّع بين سؤال البداية و«اختر المستخدم» والـ Shell حسب مرحلة التطبيق.
//

import SwiftUI

struct MrasemFlowRoot: View {
    private let context: MrasemAppContext
    @ObservedObject private var flow: MrasemAppFlow

    init(context: MrasemAppContext) {
        self.context = context
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
    }
}
