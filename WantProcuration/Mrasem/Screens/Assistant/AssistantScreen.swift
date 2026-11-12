//
//  AssistantScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/assistant/AssistantScreen.kt
//

import SwiftUI
import UIKit

/// تاب «المساعد» للضيف (01-DESIGN-SPEC §7.6).
struct AssistantScreen: View {
    @StateObject private var viewModel: AssistantViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: AssistantViewModel(
            session: context.container.session,
            assistant: context.container.assistant
        ))
    }

    var body: some View {
        AssistantContent(state: viewModel.uiState, onAsk: viewModel.onAsk)
    }
}

struct AssistantContent: View {
    @Environment(\.mrasem) private var theme

    let state: AssistantUiState
    let onAsk: (String) -> Void

    @State private var input = ""

    var body: some View {
        // تمرير لآخر المحادثة بعد كل سؤال (أول رسالة هي الترحيب فمفيش تمرير ليها).
        MrasemScreenContent(scrollToEndTrigger: state.messages.count > 1 ? state.messages.count : nil) {
            MrasemCard(
                title: mrasemString("mrasem_assistant_title"),
                headerEnd: AnyView(
                    Text(mrasemString("mrasem_assistant_demo_label"))
                        .mrasemText(theme.type.label)
                        .foregroundColor(theme.colors.muted)
                )
            ) {
                // المحادثة.
                VStack(spacing: 8) {
                    ForEach(Array(state.messages.enumerated()), id: \.offset) { _, message in
                        switch message {
                        case let .user(text):
                            MrasemChatBubble(text: text, fromMe: true)
                        case let .bot(reply):
                            MrasemChatBubble(text: mrasemAssistantReplyText(reply), fromMe: false)
                        }
                    }
                }

                // الأسئلة الجاهزة (بتلتف جنب بعض زي الـ .chips في المصدر).
                MrasemFlowLayout(spacing: 6) {
                    ForEach(Array(state.quickQuestions.enumerated()), id: \.offset) { _, question in
                        MrasemChip(question) { send(question) }
                    }
                }

                // حقل الإدخال.
                MrasemAskBar(
                    value: $input,
                    placeholder: mrasemString("mrasem_assistant_placeholder"),
                    sendLabel: mrasemString("mrasem_assistant_send"),
                    onSend: { send(input) }
                )
            }
        }
    }

    private func send(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAsk(trimmed)
        input = ""
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Previews

private enum AssistantPreviewData {
    static let state = AssistantUiState(
        messages: [
            .bot(.welcome(city: "الدوحة")),
            .user("متى موعدي القادم؟"),
            .bot(.nextItem(title: "جلسة المباحثات الرسمية", dayLabel: "الثلاثاء ٢٤", time: "09:30", place: "وزارة العدل – قاعة الاجتماعات الكبرى")),
        ],
        quickQuestions: ["ماذا ألبس اليوم؟", "متى موعدي القادم؟", "أين السيارة؟", "أريد طلب طعام", "تاكسي", "أماكن قريبة"]
    )
}

#Preview("Assistant - Light") {
    MrasemScreenPreview(.light) { AssistantContent(state: AssistantPreviewData.state, onAsk: { _ in }) }
}

#Preview("Assistant - Dark") {
    MrasemScreenPreview(.dark) { AssistantContent(state: AssistantPreviewData.state, onAsk: { _ in }) }
}
