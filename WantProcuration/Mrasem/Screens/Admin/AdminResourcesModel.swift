//
//  AdminResourcesModel.swift
//  Mrasem
//
//  Phase 15 — تاب «الموارد»: السائقون والسيارات والمرافقون وجدول التعيينات وحل التعارض.
//  كل الكتابة عبر `ResourceService` / `ProgramService` (G8).
//

import Foundation
import Combine

enum ResourceSection: String, CaseIterable, Hashable {
    case drivers
    case cars
    case escorts
    case schedule

    var titleKey: String { "mrasem_admin_res_section_" + rawValue }
}

final class AdminResourcesModel: ObservableObject {
    @Published private(set) var uiState: AdminResourcesState

    private let backend: MrasemBackend
    private let toastBus: MrasemToastBus
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend, toastBus: MrasemToastBus) {
        self.backend = backend
        self.toastBus = toastBus
        let today = backend.today
        uiState = .make(backend.database, today: today().iso)

        backend.store.publisher
            .map { AdminResourcesState.make($0, today: today().iso) }
            .removeDuplicates()
            .sink { [weak self] in self?.uiState = $0 }
            .store(in: &cancellables)
    }

    // MARK: - الحفظ والحذف (بيرجّع مفتاح الخطأ أو `nil`)

    func save(_ draft: DriverDraft) -> String? { finish(backend.resources.saveDriver(draft.record())) }
    func save(_ draft: EscortDraft) -> String? { finish(backend.resources.saveEscort(draft.record())) }

    func save(_ draft: CarDraft) -> String? {
        switch backend.resources.saveCar(draft.record()) {
        case let .failure(error):
            return error.messageKey
        case let .success(saved):
            // السواق بيتسجّل على السيارة من `assignDriver` عشان يتأكد إنه موجود.
            backend.resources.assignDriver(draft.driverId, toCar: saved.id)
            toast()
            return nil
        }
    }

    func deleteDriver(_ id: String) { backend.resources.deleteDriver(id) }
    func deleteCar(_ id: String) { backend.resources.deleteCar(id) }
    func deleteEscort(_ id: String) { backend.resources.deleteEscort(id) }

    func toggleStatus(_ id: String) {
        guard let driver = backend.database.driver(id) else { return }
        backend.resources.setDriverStatus(id, driver.status == .available ? .onLeave : .available)
    }

    // MARK: - الاختيارات

    func driverOptions() -> [PickerOption] {
        [PickerOption(id: nil, label: mrasemString("mrasem_admin_none"))]
            + backend.database.drivers.map { PickerOption(id: $0.id, label: $0.name) }
    }

    func draft(driver id: String) -> DriverDraft? { backend.database.driver(id).map { DriverDraft($0) } }
    func draft(car id: String) -> CarDraft? { backend.database.car(id).map { CarDraft($0) } }
    func draft(escort id: String) -> EscortDraft? { backend.database.escort(id).map { EscortDraft($0) } }

    // MARK: - حل التعارض

    func alternatives(forItem itemId: String) -> [CarRecord] {
        AdminResourcesBuilder.alternatives(backend.database, forItem: itemId)
    }

    /// يبدّل سيارة الفقرة (ويبلّغ الضيف بالتغيير زي أي تعديل في البرنامج).
    func resolve(itemId: String, carId: String) -> Bool {
        guard var item = backend.database.programItem(itemId) else { return false }
        item.carId = carId
        guard case .success = backend.program.save(item, notify: true) else { return false }
        toast()
        return true
    }

    private func finish<T>(_ result: Result<T, StoreValidationError>) -> String? {
        switch result {
        case let .failure(error):
            return error.messageKey
        case .success:
            toast()
            return nil
        }
    }

    private func toast() {
        toastBus.show(ToastMessage(.res("mrasem_admin_toast_saved_strong"), .res("mrasem_admin_toast_saved_rest")))
    }
}
