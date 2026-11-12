//
//  MrasemAppContext+Preview.swift
//  Mrasem
//
//  سياق للـ Previews: قاعدة في الذاكرة ببيانات العرض ومستخدم محدد (ما بيلمسش ملفات الجهاز).
//

import Foundation

private final class PreviewMrasemPreferences: MrasemPreferences {
    var lastGuestTab: GuestTab?
    func saveGuestTab(_ tab: GuestTab) { lastGuestTab = tab }
}

extension MrasemAppContext {
    static func preview(user: UserRef? = nil) -> MrasemAppContext {
        let backend = MrasemBackend(storage: InMemoryMrasemStorage())
        backend.chooseStart(demo: true)
        if let user { backend.switchUser(to: user) }
        return MrasemAppContext(backend: backend, preferences: PreviewMrasemPreferences(), confirmed: user != nil)
    }
}
