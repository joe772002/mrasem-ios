//
//  ProtocolViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/protocol/ProtocolViewModel.kt
//

import Foundation
import Combine

struct ProtocolUiState: Equatable {
    let content: ProtocolContent
}

/// حالة شاشة البروتوكول (الضيف) (01-DESIGN-SPEC §7.5).
final class ProtocolViewModel: ObservableObject {
    @Published private(set) var uiState: ProtocolUiState

    private let protocolStrategy: ProtocolStrategy
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy, protocolStrategy: ProtocolStrategy, toastBus: MrasemToastBus) {
        self.protocolStrategy = protocolStrategy
        self.toastBus = toastBus
        self.uiState = ProtocolUiState(content: protocolStrategy.content(state: session.state))

        session.statePublisher
            .map { ProtocolUiState(content: protocolStrategy.content(state: $0)) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    /// يقلب عنصر في «قبل الخروج من الفندق».
    func onCheckToggle(_ index: Int) {
        protocolStrategy.toggleCheck(index)
    }

    /// ضغطة على دليل إرشادي: توست.
    func onGuideClick(_ guide: String) {
        toastBus.show(ToastMessage(.res("mrasem_protocol_guide_toast", [guide]), nil))
    }
}
