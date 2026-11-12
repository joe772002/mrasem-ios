//
//  MrasemShell.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/shell/MrasemShell.kt
//

import SwiftUI

/// الـ Shell: هيدر ثابت + محتوى التاب الحالي + bottom bar + التوست.
/// التاب جزء من الحالة (مش back stack).
struct MrasemShell: View {
    @Environment(\.mrasem) private var theme
    @StateObject private var toast = MrasemToastState()

    private let context: MrasemAppContext
    @ObservedObject private var model: MrasemSessionViewModel

    init(context: MrasemAppContext) {
        self.context = context
        self._model = ObservedObject(wrappedValue: context.shell)
    }

    var body: some View {
        let state = model.uiState
        let tabs = state.tabs

        ZStack {
            theme.colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                MrasemHeader(
                    title: mrasemString("mrasem_brand_title"),
                    subtitle: mrasemString("mrasem_brand_subtitle"),
                    roleOptions: [mrasemString("mrasem_role_guest"), mrasemString("mrasem_role_team")],
                    roleIndex: Binding(get: { state.roleIndex }, set: { model.onRoleSelected($0) }),
                    modeOptions: [mrasemString("mrasem_mode_inbound"), mrasemString("mrasem_mode_outbound")],
                    modeIndex: Binding(get: { state.modeIndex }, set: { model.onModeSelected($0) })
                )

                // مفتاح المحتوى = الوجهة: تغيير الدور أو التاب يبني المحتوى من جديد فيرجع الـ scroll لفوق.
                MrasemDestinationContent(destination: state.destination, context: context)
                    .id(state.destination)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                MrasemBottomBar(
                    items: tabs.map { MrasemBottomBarItem(label: mrasemString($0.labelKey), icon: $0.icon) },
                    selectedIndex: Binding(
                        get: { state.tabIndex },
                        set: { model.onTabSelected(tabs[$0]) }
                    )
                )
            }
            .animation(.easeInOut(duration: 0.2), value: state.destination)

            MrasemToastHost(state: toast)
        }
        .onReceive(context.toastBus.events) { message in
            toast.show(strong: message.strong.resolve(), rest: message.rest?.resolve() ?? "")
        }
    }
}

/// محتوى الوجهة: الشاشات العشرة (٦ للضيف + ٤ للفريق). كل شاشة بتاخد `context` وتبني منه الـ ViewModel بتاعها.
/// الشاشات اللي لسه ما اتبنتش (Phases 5–7) بتعرض placeholder.
private struct MrasemDestinationContent: View {
    let destination: MrasemDestination
    let context: MrasemAppContext

    var body: some View {
        switch destination {
        case .mission:
            MissionScreen(context: context)
        case .plan:
            PlanScreen(context: context)
        case .services:
            ServicesScreen(context: context)
        case .explore:
            ExploreScreen(context: context)
        default:
            MrasemPlaceholderScreen(titleKey: destination.labelKey)
        }
    }
}

#Preview("Shell - Light") {
    MrasemShell(context: MrasemAppContext(container: MrasemContainer(preferences: MrasemShellPreviewPreferences())))
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Shell - Dark") {
    MrasemShell(context: MrasemAppContext(container: MrasemContainer(preferences: MrasemShellPreviewPreferences())))
        .mrasemTheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}

/// تفضيلات في الذاكرة للـ Previews (ما تلمسش UserDefaults).
private final class MrasemShellPreviewPreferences: MrasemPreferences {
    var lastGuestTab: GuestTab?
    func saveGuestTab(_ tab: GuestTab) { lastGuestTab = tab }
}
