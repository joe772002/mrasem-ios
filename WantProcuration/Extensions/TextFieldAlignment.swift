//
//  TextFieldAlignment.swift
//  WantProcuration
//
//  The app switches language with its own setting, so a TextField can put its text/placeholder on the
//  wrong side (left in Arabic). This pins it to the reading side: right in Arabic, left in English.
//

import SwiftUI

extension View {
    func textAlignedToReadingSide(isRTL: Bool) -> some View {
        self
            .multilineTextAlignment(isRTL ? .trailing : .leading)
            // Fixed direction so .trailing always means "right" and .leading "left".
            .environment(\.layoutDirection, .leftToRight)
    }

    /// Same, reading the app language from settings (for views that have no AppManager).
    func textAlignedToReadingSide() -> some View {
        textAlignedToReadingSide(isRTL: UserDefaults.standard.string(forKey: "selectedLanguage") != "en")
    }
}
