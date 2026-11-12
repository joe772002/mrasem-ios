//
//  AssistantViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/assistant/AssistantViewModel.kt
//

import Foundation
import Combine

struct AssistantUiState: Equatable {
    let messages: [ChatMessage]
    let quickQuestions: [String]

    static func make(_ state: MrasemState, assistant: AssistantStrategy) -> AssistantUiState {
        AssistantUiState(
            messages: assistant.conversation(state: state),
            quickQuestions: MrasemDemoData.quickQuestions
        )
    }
}

/// حالة شاشة المساعد (الضيف) (01-DESIGN-SPEC §7.6).
final class AssistantViewModel: ObservableObject {
    @Published private(set) var uiState: AssistantUiState

    private let assistant: AssistantStrategy
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, assistant: AssistantStrategy) {
        self.assistant = assistant
        self.uiState = AssistantUiState.make(session.state, assistant: assistant)

        session.statePublisher
            .map { AssistantUiState.make($0, assistant: assistant) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    /// سؤال جديد: يضيف رسالة المستخدم ورد المساعد.
    func onAsk(_ question: String) {
        _ = assistant.ask(question)
    }
}
