//
//  MrasemToastBus.swift
//  Mrasem
//
//  Mirrors Android: ui/screens/shell/MrasemToastBus.kt
//

import Foundation
import Combine

/// قناة واحدة للتوست على مستوى التطبيق: أي ViewModel يبعت، والـ Shell بيعرض.
/// الجديد بيلغي القديم (`MrasemToastState` بيعيد المؤقّت).
nonisolated final class MrasemToastBus {
    let events = PassthroughSubject<ToastMessage, Never>()

    func show(_ message: ToastMessage) {
        events.send(message)
    }
}
