//
//  ServicesScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/services/ServicesScreen.kt
//

import SwiftUI

/// تاب «الخدمات» للضيف (01-DESIGN-SPEC §7.3).
struct ServicesScreen: View {
    @StateObject private var viewModel: ServicesViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: ServicesViewModel(session: context.container.session))
    }

    var body: some View {
        ServicesContent(state: viewModel.uiState, onOpenApp: { ExternalLinks.open($0) })
    }
}

struct ServicesContent: View {
    @Environment(\.mrasem) private var theme

    let state: ServicesUiState
    let onOpenApp: (String) -> Void

    var body: some View {
        MrasemScreenContent {
            MrasemNoticesSection(notices: state.notices)

            // كارت لكل فئة خدمة.
            ForEach(Array(state.categories.enumerated()), id: \.offset) { _, category in
                MrasemCard(title: category.name) {
                    VStack(spacing: 8) {
                        ForEach(Array(category.apps.enumerated()), id: \.offset) { _, app in
                            MrasemServiceRow(
                                name: app.name,
                                nameEn: app.nameEn,
                                description: app.description,
                                logoText: app.logoLetter,
                                logoColor: MrasemRGB(hex: app.color).color,
                                actionLabel: mrasemString("mrasem_service_open"),
                                onClick: { onOpenApp(app.url) }
                            )
                        }
                    }
                }
            }

            // كارت «معلومات سريعة».
            MrasemCard(title: mrasemString("mrasem_services_quick_info")) {
                MrasemKeyValueList(state.quickInfo.map { KeyValue($0.label, $0.value) })
            }

            // سطر رقم الغرفة تحت الكارت.
            Text(mrasemString("mrasem_services_hotel_delivery", [state.hotelRoom]))
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.muted)
        }
    }
}

// MARK: - Previews

private enum ServicesPreviewData {
    static func state(_ mode: MissionMode) -> ServicesUiState {
        var state = MrasemState(missions: MrasemDemoData.missions)
        state.mode = mode
        return ServicesUiState.make(state)
    }
}

#Preview("Services inbound - Light") {
    MrasemScreenPreview(.light) { ServicesContent(state: ServicesPreviewData.state(.inbound), onOpenApp: { _ in }) }
}

#Preview("Services inbound - Dark") {
    MrasemScreenPreview(.dark) { ServicesContent(state: ServicesPreviewData.state(.inbound), onOpenApp: { _ in }) }
}

#Preview("Services outbound - Light") {
    MrasemScreenPreview(.light) { ServicesContent(state: ServicesPreviewData.state(.outbound), onOpenApp: { _ in }) }
}
