//
//  AdminNavigator.swift
//  Mrasem
//
//  Phase 14 — تنقّل الأدمن بين التابات: لوحة التحكم تفتح تفاصيل وفد معيّن في تاب «الوفود».
//

import Foundation

final class AdminNavigator: ObservableObject {
    /// الوفد المفتوح تفاصيله في تاب «الوفود» (`nil` = القائمة).
    @Published var openDelegationId: String?

    func open(_ delegationId: String) {
        openDelegationId = delegationId
    }

    func close() {
        openDelegationId = nil
    }
}
