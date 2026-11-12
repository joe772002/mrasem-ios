//
//  AdminRequestsModel.swift
//  Mrasem
//
//  Phase 15 — تاب «الطلبات والتنبيهات»: فلتر الطلبات، الرد، «تم»، الإضافة للبرنامج، وإرسال تنبيه لجمهور في وفد.
//

import Foundation
import Combine

final class AdminRequestsModel: ObservableObject {
    @Published private(set) var uiState: AdminRequestsState

    private let backend: MrasemBackend
    private let toastBus: MrasemToastBus
    private var filter: RequestFilter = .new
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend, toastBus: MrasemToastBus) {
        self.backend = backend
        self.toastBus = toastBus
        uiState = .make(backend.database, filter: .new)

        backend.store.publisher
            .sink { [weak self] db in
                guard let self else { return }
                let next = AdminRequestsState.make(db, filter: self.filter)
                if next != self.uiState { self.uiState = next }
            }
            .store(in: &cancellables)
    }

    func onFilter(_ value: RequestFilter) {
        filter = value
        uiState = .make(backend.database, filter: value)
    }

    // MARK: - الطلبات

    func resolve(_ id: String) {
        guard backend.requests.resolve(id) else { return }
        toast("mrasem_admin_toast_request_done")
    }

    func replyDraft(_ id: String) -> RequestReplyDraft {
        RequestReplyDraft(requestId: id, text: backend.database.requests.first { $0.id == id }?.reply ?? "")
    }

    func reply(_ draft: RequestReplyDraft) -> String? {
        guard backend.requests.reply(draft.requestId, text: draft.text) else { return "mrasem_admin_error_reply" }
        toast("mrasem_admin_toast_request_replied")
        return nil
    }

    /// مسوّدة «إضافة للبرنامج»: أول يوم في الوفد من النهاردة وبعده (أو أول يوم لو الوفد خلص).
    func programDraft(_ id: String) -> RequestProgramDraft? {
        let days = programDays(id)
        guard let first = days.first(where: { $0 >= backend.today().iso }) ?? days.first else { return nil }
        return RequestProgramDraft(requestId: id, date: first)
    }

    func programDays(_ id: String) -> [String] {
        guard let request = backend.database.requests.first(where: { $0.id == id }),
              let delegation = backend.database.delegation(request.delegationId) else { return [] }
        return DelegationService.days(of: delegation)
    }

    func carOptions() -> [PickerOption] {
        AdminOptions.cars(backend.database, none: mrasemString("mrasem_admin_none"))
    }

    func addToProgram(_ draft: RequestProgramDraft) -> String? {
        switch backend.requests.addToProgram(draft.requestId, date: draft.date, time: draft.time.storeLatinDigits, carId: draft.carId) {
        case let .failure(error):
            return error.messageKey
        case .success:
            toast("mrasem_admin_toast_request_added")
            return nil
        }
    }

    // MARK: - التنبيهات

    func broadcastDraft() -> BroadcastDraft? {
        backend.database.delegations.first.map { BroadcastDraft(delegationId: $0.id) }
    }

    func delegationOptions() -> [PickerOption] {
        backend.database.delegations.map { PickerOption(id: $0.id, label: $0.name) }
    }

    func send(_ draft: BroadcastDraft) -> String? {
        guard backend.requests.broadcast(draft.text, delegationId: draft.delegationId, audience: draft.audience) else {
            return "mrasem_admin_error_broadcast"
        }
        toast("mrasem_admin_toast_broadcast_sent")
        return nil
    }

    private func toast(_ restKey: String) {
        toastBus.show(ToastMessage(.res("mrasem_admin_toast_saved_strong"), .res(restKey)))
    }
}
