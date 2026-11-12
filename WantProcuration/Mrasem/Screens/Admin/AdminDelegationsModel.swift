//
//  AdminDelegationsModel.swift
//  Mrasem
//
//  Phase 14 — قائمة الوفود للأدمن: الفلتر، الإضافة، وفتح التفاصيل.
//

import Foundation
import Combine

struct AdminDelegationsState: Equatable {
    let filter: DelegationFilter
    let rows: [DelegationRow]
    let counts: [DelegationFilter: Int]
    let hasAny: Bool

    static func make(_ db: MrasemDatabase, filter: DelegationFilter) -> AdminDelegationsState {
        AdminDelegationsState(
            filter: filter,
            rows: AdminDelegationList.rows(db, filter: filter),
            counts: AdminDelegationList.counts(db),
            hasAny: !db.delegations.isEmpty
        )
    }
}

final class AdminDelegationsModel: ObservableObject {
    @Published private(set) var uiState: AdminDelegationsState

    private let backend: MrasemBackend
    private let nav: AdminNavigator
    private let toastBus: MrasemToastBus
    private var filter: DelegationFilter = .all
    private var cancellables = Set<AnyCancellable>()

    init(backend: MrasemBackend, nav: AdminNavigator, toastBus: MrasemToastBus) {
        self.backend = backend
        self.nav = nav
        self.toastBus = toastBus
        uiState = .make(backend.database, filter: .all)

        backend.store.publisher
            .sink { [weak self] db in
                guard let self else { return }
                let next = AdminDelegationsState.make(db, filter: self.filter)
                if next != self.uiState { self.uiState = next }
            }
            .store(in: &cancellables)
    }

    func onFilter(_ value: DelegationFilter) {
        filter = value
        uiState = .make(backend.database, filter: value)
    }

    func onOpen(_ id: String) {
        nav.open(id)
    }

    /// مسوّدة وفد جديد: يبدأ النهاردة وينتهي بعد يومين.
    func newDraft() -> DelegationDraft {
        let today = backend.today()
        let days = StoreTime.days(from: today.iso, to: Self.addDays(today, 2))
        return DelegationDraft(start: days.first ?? today.iso, end: days.last ?? today.iso)
    }

    func hotels() -> [PickerOption] { AdminOptions.hotels(backend.database, none: mrasemString("mrasem_admin_none")) }
    func venues() -> [PickerOption] { AdminOptions.venues(backend.database, none: mrasemString("mrasem_admin_none")) }

    /// بيرجّع مفتاح رسالة الخطأ، أو `nil` لو اتحفظ (وبيفتح تفاصيل الوفد الجديد).
    func save(_ draft: DelegationDraft) -> String? {
        switch backend.delegations.save(draft.record()) {
        case let .failure(error):
            return error.messageKey
        case let .success(saved):
            toastBus.show(ToastMessage(.res("mrasem_admin_toast_saved_strong"), .res("mrasem_admin_toast_saved_rest")))
            nav.open(saved.id)
            return nil
        }
    }

    private static func addDays(_ date: MrasemDate, _ days: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
        guard let base = calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)),
              let moved = calendar.date(byAdding: .day, value: days, to: base) else { return date.iso }
        let c = calendar.dateComponents([.year, .month, .day], from: moved)
        return MrasemDate(year: c.year ?? date.year, month: c.month ?? date.month, day: c.day ?? date.day).iso
    }
}
