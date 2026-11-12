//
//  FormTextFieldRow.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 08/10/2025.
//

import SwiftUI
// MARK: - Form TextField Row
struct FormTextFieldRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let required: Bool
    let keyboardType: UIKeyboardType
    let maxLength: Int?
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        required: Bool = false,
        keyboardType: UIKeyboardType = .default,
        maxLength: Int? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.required = required
        self.keyboardType = keyboardType
        self.maxLength = maxLength
    }
    
    var body: some View {
        FormRow(title: title, required: required) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textAlignedToReadingSide()
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .font(Font.setFontRegular())
                .foregroundStyle(Color.theme.secondaryText)
                .frame(height: 50)
                .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isFocused ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isFocused ? 2 : 1)
                }
                .animation(.easeInOut(duration: 0.2), value: isFocused)
                .limitText($text, to: maxLength ?? Int.max)
        }
    }
}
