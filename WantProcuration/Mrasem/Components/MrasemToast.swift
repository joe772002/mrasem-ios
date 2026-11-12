//
//  MrasemToast.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemToast.kt
//

import SwiftUI
import UIKit
import Combine

/// مدة التوست بالثواني.
private let toastDuration: Duration = .milliseconds(3800)

/// حالة التوست: اسـتدعِ `show()` من أي مكان. كل استدعاء يعيد المؤقّت.
nonisolated final class MrasemToastState: ObservableObject {
    @Published private(set) var strong: String = ""
    @Published private(set) var rest: String = ""
    @Published private(set) var visible: Bool = false

    /// بيتزود مع كل `show()` — عشان نعيد ضبط المؤقّت.
    @Published private(set) var tick: Int = 0

    func show(strong: String, rest: String = "") {
        self.strong = strong
        self.rest = rest
        visible = true
        tick += 1
    }

    func hide() {
        visible = false
    }
}

/// يوضع فوق المحتوى (في ZStack الجذر). يظهر أعلى الشاشة بحد ذهبي.
struct MrasemToastHost: View {
    @Environment(\.mrasem) private var theme

    @ObservedObject var state: MrasemToastState

    init(state: MrasemToastState) {
        self.state = state
    }

    var body: some View {
        let c = theme.colors

        VStack(spacing: 0) {
            if state.visible {
                Text(attributedText)
                    .font(theme.type.bodySm.font)
                    .lineSpacing(theme.type.bodySm.lineSpacing)
                    .tracking(theme.type.bodySm.tracking)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(c.ink, in: RoundedRectangle(cornerRadius: theme.shapes.toast))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .task(id: state.tick) {
            guard state.tick > 0 else { return }
            // VoiceOver: التوست مش بياخد focus، فبنعلنه (زي liveRegion في Android).
            let spoken = [state.strong, state.rest].filter { !$0.isEmpty }.joined(separator: " ")
            UIAccessibility.post(notification: .announcement, argument: spoken)
            try? await Task.sleep(for: toastDuration)
            guard !Task.isCancelled else { return }
            state.hide()
        }
    }

    /// الجزء الذهبي Bold والباقي عادي — زي `buildAnnotatedString` في Android.
    private var attributedText: AttributedString {
        var attributed = AttributedString(state.strong)
        attributed.font = theme.type.bodySm.font
        attributed.foregroundColor = theme.colors.gold

        if !state.rest.isEmpty {
            var tail = AttributedString(state.strong.isEmpty ? state.rest : " " + state.rest)
            tail.font = theme.type.bodySm.font
            tail.foregroundColor = theme.colors.bg
            attributed.append(tail)
        }

        return attributed
    }
}
