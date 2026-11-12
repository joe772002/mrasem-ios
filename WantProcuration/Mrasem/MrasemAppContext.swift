//
//  MrasemAppContext.swift
//  Mrasem
//
//  بديل Hilt للـ UI: بيمسك القاعدة المحلية والـ container والـ toast bus وحالة التطبيق وحالة الـ Shell،
//  وبيتمرر من الـ Shell لكل شاشة (الشاشة بتبني ViewModel بتاعها منه).
//

import Foundation
import Combine

nonisolated final class MrasemAppContext: ObservableObject {
    let backend: MrasemBackend
    let container: MrasemContainer
    let toastBus: MrasemToastBus
    let flow: MrasemAppFlow
    let roleShell: RoleShellModel
    let adminNav = AdminNavigator()

    /// `confirmed: true` للـ Previews عشان تفتح على الـ Shell مباشرة بالمستخدم الحالي.
    init(
        backend: MrasemBackend = MrasemBackend(),
        preferences: MrasemPreferences = UserDefaultsMrasemPreferences(),
        toastBus: MrasemToastBus = MrasemToastBus(),
        confirmed: Bool = false
    ) {
        let container = MrasemContainer(repository: backend.repository, preferences: preferences)
        self.backend = backend
        self.container = container
        self.toastBus = toastBus
        self.flow = MrasemAppFlow(backend: backend, confirmed: confirmed)
        self.roleShell = RoleShellModel(backend: backend, session: container.session)
    }
}
