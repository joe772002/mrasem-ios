//
//  MrasemShell.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/shell/MrasemShell.kt
//

import SwiftUI

/// الـ Shell: هيدر المستخدم + محتوى التاب الحالي + bottom bar + التوست.
/// التابات حسب دور المستخدم الحالي (Phase 13).
struct MrasemShell: View {
    @Environment(\.mrasem) private var theme
    @StateObject private var toast = MrasemToastState()
    @State private var showSettings = false

    private let context: MrasemAppContext
    @ObservedObject private var model: RoleShellModel

    init(context: MrasemAppContext) {
        self.context = context
        self._model = ObservedObject(wrappedValue: context.roleShell)
    }

    /// مفتاح المحتوى: تغيير التاب أو الوفد يبني الشاشة من جديد فيرجع الـ scroll لفوق.
    private struct ContentKey: Hashable {
        let tab: RoleTab
        let delegation: String?
    }

    var body: some View {
        let state = model.uiState

        ZStack {
            theme.colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                MrasemUserHeader(
                    title: mrasemString("mrasem_brand_title"),
                    subtitle: mrasemString("mrasem_brand_subtitle"),
                    userName: state.userName,
                    roleLabel: mrasemString(state.role.labelKey),
                    unread: state.unread,
                    delegations: state.delegations,
                    selectedDelegationId: state.selectedDelegationId,
                    onSwitchUser: { context.flow.openPicker() },
                    onSelectDelegation: { model.select(delegation: $0) },
                    onSettings: state.role == .admin ? { showSettings = true } : nil
                )

                content(state)
                    .id(ContentKey(tab: state.selected, delegation: state.selectedDelegationId))
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                MrasemBottomBar(
                    items: state.tabs.map { MrasemBottomBarItem(label: mrasemString($0.labelKey), icon: $0.icon) },
                    selectedIndex: Binding(
                        get: { state.tabIndex },
                        set: { if state.tabs.indices.contains($0) { model.select(state.tabs[$0]) } }
                    )
                )
            }
            .animation(.easeInOut(duration: 0.2), value: state.selected)

            MrasemToastHost(state: toast)
        }
        .sheet(isPresented: $showSettings) {
            AdminSettingsScreen(context: context)
        }
        .onReceive(context.toastBus.events) { message in
            toast.show(strong: message.strong.resolve(), rest: message.rest?.resolve() ?? "")
        }
    }

    @ViewBuilder
    private func content(_ state: RoleShellState) -> some View {
        if state.needsDelegation && !state.hasDelegation {
            MrasemEmptyScopeScreen()
        } else {
            switch state.selected {
            case let .screen(destination):
                MrasemDestinationContent(destination: destination, context: context)
            case let .admin(tab):
                AdminTabContent(tab: tab, context: context)
            case let .driver(tab):
                DriverTabContent(tab: tab, context: context)
            case let .escort(tab):
                EscortTabContent(tab: tab, context: context)
            }
        }
    }
}

/// محتوى الوجهة: الشاشات العشرة (٦ للضيف + ٤ للفريق). كل شاشة بتاخد `context` وتبني منه الـ ViewModel بتاعها.
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
        case .protocol:
            ProtocolScreen(context: context)
        case .assistant:
            AssistantScreen(context: context)
        case .teamVisit:
            TeamVisitScreen(context: context)
        case .teamChanges:
            TeamChangesScreen(context: context)
        case .teamRequests:
            TeamRequestsScreen(context: context)
        case .teamArchive:
            TeamArchiveScreen(context: context)
        }
    }
}

/// تابات الأدمن (Phase 14–15).
private struct AdminTabContent: View {
    let tab: AdminTab
    let context: MrasemAppContext

    var body: some View {
        switch tab {
        case .home:
            AdminHomeScreen(context: context)
        case .delegations:
            AdminDelegationsScreen(context: context)
        case .resources:
            AdminResourcesScreen(context: context)
        case .places:
            AdminPlacesScreen(context: context)
        case .requests:
            AdminRequestsScreen(context: context)
        }
    }
}

/// تابات السائق (Phase 16).
private struct DriverTabContent: View {
    let tab: DriverTab
    let context: MrasemAppContext

    var body: some View {
        switch tab {
        case .trips: DriverTripsScreen(context: context)
        case .schedule: DriverScheduleScreen(context: context)
        }
    }
}

/// تابات المرافق (Phase 16).
private struct EscortTabContent: View {
    let tab: EscortTab
    let context: MrasemAppContext

    var body: some View {
        switch tab {
        case .delegation: EscortDelegationScreen(context: context)
        case .notices: NoticesScreen(context: context)
        }
    }
}

/// المستخدم ملوش وفد (أو اتحذف وفده): رسالة بدل شاشة فاضية (G5).
struct MrasemEmptyScopeScreen: View {
    @Environment(\.mrasem) private var theme

    var body: some View {
        VStack(spacing: 8) {
            Text("mrasem_empty_scope_title")
                .mrasemText(theme.type.cardTitle)
                .foregroundColor(theme.colors.maroon)
                .accessibilityAddTraits(.isHeader)
            Text("mrasem_empty_scope_message")
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(theme.colors.bg)
    }
}

#Preview("Shell - Member - Light") {
    MrasemShell(context: .preview(user: .member("m1")))
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Shell - Coordinator - Dark") {
    MrasemShell(context: .preview(user: .team("u2")))
        .mrasemTheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Shell - Admin - Light") {
    MrasemShell(context: .preview(user: .team("u1")))
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}
