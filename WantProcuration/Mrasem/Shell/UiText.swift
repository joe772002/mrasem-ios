//
//  UiText.swift
//  Mrasem
//
//  Mirrors Android: ui/screens/shell/MrasemToastBus.kt (UiText + ToastMessage)
//

import Foundation

/// نص بيتحل وقت العرض: من الـ strings (مفتاح + متغيّرات) أو نص حرفي (بيانات / إدخال المستخدم).
nonisolated enum UiText {
    case res(String, [CVarArg] = [])
    case raw(String)

    func resolve() -> String {
        switch self {
        case let .res(key, args): return mrasemString(key, args)
        case let .raw(text): return text
        }
    }
}

/// توست مراسم: جزء بولد (ذهبي) + باقي الجملة.
nonisolated struct ToastMessage {
    let strong: UiText
    let rest: UiText?

    init(_ strong: UiText, _ rest: UiText? = nil) {
        self.strong = strong
        self.rest = rest
    }
}
