//
//  ServicesViewModel.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/services/ServicesViewModel.kt
//

import Foundation
import Combine

struct ServiceAppUi: Equatable {
    let name: String
    let nameEn: String?
    /// أول حرف من الاسم الإنجليزي (شعار الخدمة).
    let logoLetter: String
    /// لون الشعار ARGB (من البيانات).
    let color: UInt32
    let description: String
    let url: String
}

struct ServiceCategoryUi: Equatable {
    let name: String
    let apps: [ServiceAppUi]
}

struct QuickInfoUi: Equatable {
    let label: String
    let value: String
}

struct ServicesUiState: Equatable {
    let notices: [Notice]
    let categories: [ServiceCategoryUi]
    let quickInfo: [QuickInfoUi]
    let hotelRoom: String

    /// يحوّل حالة التطبيق لحالة شاشة الخدمات (مفصولة عشان الـ previews والاختبارات تستخدمها).
    static func make(_ state: MrasemState) -> ServicesUiState {
        let mission = state.mission
        return ServicesUiState(
            notices: state.recentNotices(),
            categories: mission.services.map { category in
                ServiceCategoryUi(
                    name: category.name,
                    apps: category.apps.map { app in
                        ServiceAppUi(
                            name: app.name,
                            nameEn: app.nameEn != app.name ? app.nameEn : nil,
                            logoLetter: String(app.nameEn.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)),
                            color: app.color,
                            description: app.description,
                            url: app.url
                        )
                    }
                )
            },
            quickInfo: mission.quickInfo.map { QuickInfoUi(label: $0.label, value: $0.value) },
            hotelRoom: mission.hotel.room
        )
    }
}

/// حالة شاشة الخدمات (الضيف) (01-DESIGN-SPEC §7.3).
final class ServicesViewModel: ObservableObject {
    @Published private(set) var uiState: ServicesUiState
    private var cancellables = Set<AnyCancellable>()

    init(session: MrasemSessionStrategy) {
        self.uiState = ServicesUiState.make(session.state)

        session.statePublisher
            .map { ServicesUiState.make($0) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }
}
