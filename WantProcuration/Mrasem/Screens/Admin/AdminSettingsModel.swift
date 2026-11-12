//
//  AdminSettingsModel.swift
//  Mrasem
//
//  Phase 15 — الإعدادات: الفريق والصلاحيات، التفضيلات، محتوى الوجهة، وإدارة البيانات.
//  الحذف الشامل (وفد / كل البيانات / إعادة بيانات العرض) بيتأكد منه الـ UI قبل ما ينده هنا (G3).
//

import Foundation
import Combine

final class AdminSettingsModel: ObservableObject {
    @Published private(set) var uiState: AdminSettingsState

    private let backend: MrasemBackend
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend, toastBus: MrasemToastBus) {
        self.backend = backend
        self.toastBus = toastBus
        uiState = .make(backend.database)

        backend.store.publisher
            .map { AdminSettingsState.make($0) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    // MARK: - الفريق

    func draft(team id: String) -> TeamUserDraft? { backend.database.teamUser(id).map { TeamUserDraft($0) } }

    func save(_ draft: TeamUserDraft) -> String? {
        switch backend.resources.saveTeamUser(draft.record()) {
        case let .failure(error):
            return error.messageKey
        case .success:
            savedToast()
            return nil
        }
    }

    /// آخر أدمن ما بيتحذفش: بنبلّغ بتوست بدل ما نسكت (G5).
    func deleteTeam(_ id: String) {
        if !backend.resources.deleteTeamUser(id) {
            toastBus.show(ToastMessage(.res("mrasem_admin_toast_error_strong"), .res("mrasem_admin_error_last_admin")))
        }
    }

    // MARK: - التفضيلات

    func set(_ keyPath: WritableKeyPath<PreferencesRecord, Bool>, _ value: Bool) {
        backend.resources.updatePreferences { $0[keyPath: keyPath] = value }
    }

    func set(theme: ThemeChoice) {
        backend.resources.updatePreferences { $0.theme = theme }
    }

    func set(defaultMode: MissionMode) {
        backend.resources.updatePreferences { $0.defaultMode = defaultMode }
    }

    // MARK: - الوجهات

    func newDestination() -> DestinationDraft {
        var draft = DestinationDraft()
        draft.mode = backend.database.preferences.defaultMode
        return draft
    }

    func draft(destination id: String) -> DestinationDraft? {
        backend.database.destination(id).map { DestinationDraft($0) }
    }

    func save(_ draft: DestinationDraft) -> String? {
        switch backend.resources.saveDestination(draft.record()) {
        case let .failure(error):
            return error.messageKey
        case .success:
            savedToast()
            return nil
        }
    }

    func deleteDestination(_ id: String) { backend.resources.deleteDestination(id) }

    // MARK: - إدارة البيانات

    @discardableResult
    func deleteDelegation(_ id: String) -> Bool { backend.delegations.delete(id) }

    func reloadDemo() { backend.reloadDemo() }

    func wipeAll() { backend.wipeAll() }

    private func savedToast() {
        toastBus.show(ToastMessage(.res("mrasem_admin_toast_saved_strong"), .res("mrasem_admin_toast_saved_rest")))
    }
}
