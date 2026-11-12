//
//  MrasemAppContext.swift
//  Mrasem
//
//  بديل Hilt للـ UI: بيمسك الـ container والـ toast bus والـ ViewModel بتاع الـ Shell،
//  وبيتمرر من الـ Shell لكل شاشة (الشاشة بتبني ViewModel بتاعها منه).
//

import Foundation

final class MrasemAppContext: ObservableObject {
    let container: MrasemContainer
    let toastBus: MrasemToastBus
    let shell: MrasemSessionViewModel

    init(container: MrasemContainer = MrasemContainer(), toastBus: MrasemToastBus = MrasemToastBus()) {
        self.container = container
        self.toastBus = toastBus
        self.shell = MrasemSessionViewModel(session: container.session)
    }
}
