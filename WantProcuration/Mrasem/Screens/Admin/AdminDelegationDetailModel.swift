//
//  AdminDelegationDetailModel.swift
//  Mrasem
//
//  Phase 14 — تفاصيل وفد للأدمن. كل الكتابة بتعدّي على الـ services (G8)، والتنبيهات بتتوزع من هناك.
//

import Foundation
import Combine

final class AdminDelegationDetailModel: ObservableObject {
    @Published private(set) var uiState: AdminDelegationDetail?

    private let backend: MrasemBackend
    private let delegationId: String
    private let nav: AdminNavigator
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend, delegationId: String, nav: AdminNavigator, toastBus: MrasemToastBus) {
        self.backend = backend
        self.delegationId = delegationId
        self.nav = nav
        self.toastBus = toastBus
        uiState = AdminDelegationDetailBuilder.make(backend.database, id: delegationId)

        // أول قيمة اتقرت فوق؛ بعدها أي تغيير. لو الوفد اتحذف نرجع للقائمة.
        backend.store.publisher
            .dropFirst()
            .sink { [weak self] db in
                guard let self else { return }
                let next = AdminDelegationDetailBuilder.make(db, id: self.delegationId)
                if next != self.uiState { self.uiState = next }
                if next == nil { self.nav.close() }
            }
            .store(in: &cancellables)
    }

    func close() { nav.close() }

    // MARK: - الوفد

    func delegationDraft() -> DelegationDraft? {
        backend.database.delegation(delegationId).map { DelegationDraft($0) }
    }

    func saveDelegation(_ draft: DelegationDraft) -> String? {
        finish(backend.delegations.save(draft.record()))
    }

    func setStatus(_ status: DelegationStatus) {
        backend.delegations.setStatus(delegationId, status)
        toast("mrasem_admin_toast_status_strong", "mrasem_admin_toast_status_rest")
    }

    func deleteDelegation() {
        backend.delegations.delete(delegationId)
        toast("mrasem_admin_toast_deleted_strong", "mrasem_admin_toast_deleted_rest")
    }

    // MARK: - الأعضاء

    func memberDraft(_ id: String?) -> MemberDraft {
        id.flatMap { backend.database.member($0) }.map { MemberDraft($0) } ?? MemberDraft(delegationId: delegationId)
    }

    func saveMember(_ draft: MemberDraft) -> String? {
        finish(backend.delegations.saveMember(draft.record()))
    }

    func deleteMember(_ id: String) {
        backend.delegations.deleteMember(id)
        toast("mrasem_admin_toast_deleted_strong", "mrasem_admin_toast_deleted_rest")
    }

    // MARK: - البرنامج

    func itemDraft(_ id: String?, date: String? = nil) -> ProgramDraft {
        let db = backend.database
        if let item = db.programItem(id) {
            return ProgramDraft(item, notify: db.preferences.autoNotifyGuests)
        }
        return ProgramDraft(delegationId: delegationId, date: date ?? defaultDate(db), notify: db.preferences.autoNotifyGuests)
    }

    func saveItem(_ draft: ProgramDraft) -> String? {
        finish(backend.program.save(draft.record(), notify: draft.notify))
    }

    func deleteItem(_ id: String) {
        backend.program.delete(id)
        toast("mrasem_admin_toast_deleted_strong", "mrasem_admin_toast_deleted_rest")
    }

    func postpone(_ id: String) {
        guard backend.program.postpone(id) != nil else { return }
        toast("mrasem_admin_toast_postponed_strong", "mrasem_admin_toast_postponed_rest")
    }

    /// أيام الوفد لاختيار يوم الفقرة.
    var days: [String] {
        backend.database.delegation(delegationId).map(DelegationService.days(of:)) ?? []
    }

    // MARK: - الطلبات

    func resolve(_ requestId: String) {
        guard backend.requests.resolve(requestId) else { return }
        toast("mrasem_team_toast_resolved_strong", "mrasem_team_toast_resolved_rest")
    }

    // MARK: - الاختيارات

    private var none: String { mrasemString("mrasem_admin_none") }

    func hotels() -> [PickerOption] { AdminOptions.hotels(backend.database, none: none) }
    func venues() -> [PickerOption] { AdminOptions.venues(backend.database, none: none) }
    func places() -> [PickerOption] { AdminOptions.places(backend.database, none: none) }
    func escorts() -> [PickerOption] { AdminOptions.escorts(backend.database, none: none) }
    func cars() -> [PickerOption] { AdminOptions.cars(backend.database, none: none) }

    // MARK: - داخلي

    /// اليوم لو جوه فترة الوفد، وإلا أول يوم.
    private func defaultDate(_ db: MrasemDatabase) -> String {
        let days = db.delegation(delegationId).map(DelegationService.days(of:)) ?? []
        let today = backend.today().iso
        return days.contains(today) ? today : (days.first ?? today)
    }

    private func finish<T>(_ result: Result<T, StoreValidationError>) -> String? {
        switch result {
        case let .failure(error):
            return error.messageKey
        case .success:
            toast("mrasem_admin_toast_saved_strong", "mrasem_admin_toast_saved_rest")
            return nil
        }
    }

    private func toast(_ strong: String, _ rest: String) {
        toastBus.show(ToastMessage(.res(strong), .res(rest)))
    }
}
