//
//  AdminSettingsScreen.swift
//  Mrasem
//
//  Phase 15 — الإعدادات (من زر الهيدر): الفريق والصلاحيات، الإشعارات، النشر، المظهر، محتوى الوجهة، وإدارة البيانات.
//

import SwiftUI

struct AdminSettingsScreen: View {
    @StateObject private var model: AdminSettingsModel
    @State private var team: TeamUserDraft?
    @State private var destination: DestinationDraft?

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: AdminSettingsModel(backend: context.backend, toastBus: context.toastBus))
    }

    var body: some View {
        AdminSettingsContent(
            state: model.uiState,
            onAddTeam: { team = TeamUserDraft() },
            onEditTeam: { team = model.draft(team: $0) },
            onToggle: model.set,
            onTheme: model.set(theme:),
            onMode: model.set(defaultMode:),
            onAddDestination: { destination = model.newDestination() },
            onEditDestination: { destination = model.draft(destination: $0) },
            onDeleteDelegation: { model.deleteDelegation($0) },
            onReloadDemo: model.reloadDemo,
            onWipeAll: model.wipeAll
        )
        .sheet(item: $team) { draft in
            TeamUserFormSheet(draft: draft, onSave: model.save, onDelete: draft.isNew ? nil : { model.deleteTeam(draft.id) })
        }
        .sheet(item: $destination) { draft in
            DestinationFormSheet(draft: draft, onSave: model.save,
                                 onDelete: draft.isNew ? nil : { model.deleteDestination(draft.id) })
        }
    }
}

struct AdminSettingsContent: View {
    @Environment(\.mrasem) private var theme
    @Environment(\.dismiss) private var dismiss

    let state: AdminSettingsState
    let onAddTeam: () -> Void
    let onEditTeam: (String) -> Void
    let onToggle: (WritableKeyPath<PreferencesRecord, Bool>, Bool) -> Void
    let onTheme: (ThemeChoice) -> Void
    let onMode: (MissionMode) -> Void
    let onAddDestination: () -> Void
    let onEditDestination: (String) -> Void
    let onDeleteDelegation: (String) -> Void
    let onReloadDemo: () -> Void
    let onWipeAll: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                Text("mrasem_admin_settings_title")
                    .mrasemText(theme.type.heroDest)
                    .foregroundColor(theme.colors.maroon)
                    .accessibilityAddTraits(.isHeader)

                teamCard
                // المفاتيح الموصّلة فعلاً بس (Phase 18). الملخص اليومي وموافقة النشر وإشعارات الجهاز
                // موجودين في `PreferencesRecord` بس من غير تنفيذ، فمش ظاهرين عشان ما يضلّلوش.
                toggles("mrasem_admin_settings_notifications", [
                    ("mrasem_admin_pref_new_request", \.notifyNewRequest),
                    ("mrasem_admin_pref_conflict", \.notifyConflict)
                ])
                toggles("mrasem_admin_settings_publishing", [
                    ("mrasem_admin_pref_auto_notify", \.autoNotifyGuests)
                ])
                appearanceCard
                destinationsCard
                AdminDataManagementCard(
                    state: state, onDeleteDelegation: onDeleteDelegation, onReloadDemo: onReloadDemo, onWipeAll: onWipeAll
                )

                MrasemButton(mrasemString("mrasem_admin_settings_close"), variant: .ghost, block: true) { dismiss() }
            }
            .padding(theme.dimens.screenHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.bg.ignoresSafeArea())
    }

    // MARK: - الفريق

    private var teamCard: some View {
        MrasemCard(
            title: mrasemString("mrasem_admin_settings_team"),
            headerEnd: AnyView(MrasemButton(mrasemString("mrasem_admin_team_add"), variant: .ghost, action: onAddTeam))
        ) {
            VStack(spacing: 8) {
                ForEach(state.team) { row in
                    MrasemActionRow(
                        title: row.name,
                        subtitle: mrasemString("mrasem_admin_team_subtitle", [row.phone.toArabicDigits(), row.email])
                    ) {
                        MrasemPill(mrasemString(row.role.adminLabelKey), kind: row.role == .admin ? .ok : .neutral)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onEditTeam(row.id) }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }

    // MARK: - المفاتيح

    private func toggles(_ titleKey: String, _ items: [(String, WritableKeyPath<PreferencesRecord, Bool>)]) -> some View {
        MrasemCard(title: mrasemString(titleKey)) {
            VStack(spacing: 0) {
                ForEach(items, id: \.0) { key, path in
                    AdminToggleRow(
                        label: mrasemString(key),
                        isOn: Binding(get: { state.preferences[keyPath: path] }, set: { onToggle(path, $0) })
                    )
                }
            }
        }
    }

    private var appearanceCard: some View {
        MrasemCard(title: mrasemString("mrasem_admin_settings_appearance")) {
            VStack(spacing: 10) {
                ValueSelect(
                    label: mrasemString("mrasem_admin_pref_theme"), values: ThemeChoice.allCases,
                    title: { mrasemString($0.adminLabelKey) },
                    selection: Binding(get: { state.preferences.theme }, set: onTheme)
                )
                ValueSelect(
                    label: mrasemString("mrasem_admin_pref_default_mode"), values: MissionMode.allCases,
                    title: { mrasemString($0.adminLabelKey) },
                    selection: Binding(get: { state.preferences.defaultMode }, set: onMode)
                )
            }
        }
    }

    // MARK: - الوجهات

    private var destinationsCard: some View {
        MrasemCard(
            title: mrasemString("mrasem_admin_settings_destinations"),
            headerEnd: AnyView(MrasemButton(mrasemString("mrasem_admin_dest_add"), variant: .ghost, action: onAddDestination))
        ) {
            VStack(spacing: 8) {
                if state.destinations.isEmpty {
                    Text("mrasem_admin_dest_empty")
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.muted)
                }
                ForEach(state.destinations) { row in
                    MrasemActionRow(title: row.name, subtitle: mrasemString(row.mode.adminLabelKey))
                        .contentShape(Rectangle())
                        .onTapGesture { onEditDestination(row.id) }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
}

#Preview("Admin settings - Light") {
    MrasemScreenPreview(.light) {
        AdminSettingsContent(
            state: .make(MrasemSeed.demo()), onAddTeam: {}, onEditTeam: { _ in }, onToggle: { _, _ in },
            onTheme: { _ in }, onMode: { _ in }, onAddDestination: {}, onEditDestination: { _ in },
            onDeleteDelegation: { _ in }, onReloadDemo: {}, onWipeAll: {}
        )
    }
}
