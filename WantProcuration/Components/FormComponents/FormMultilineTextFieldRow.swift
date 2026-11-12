//
//  FormMultilineTextFieldRow.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 08/10/2025.
//

import SwiftUI

// MARK: - Form Multiline TextField Row
struct FormMultilineTextFieldRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let required: Bool
    let maxLength: Int?
    let minHeight: CGFloat
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        required: Bool = false,
        maxLength: Int? = nil,
        minHeight: CGFloat = 100
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.required = required
        self.maxLength = maxLength
        self.minHeight = minHeight
    }
    
    var body: some View {
        FormRow(title: title, required: required) {
            VStack(spacing: 0) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.clear)
                    .font(Font.setFontRegular())
                    .foregroundStyle(Color.theme.secondaryText)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(Font.setFontRegular()) // Added font here
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                
                if let maxLength = maxLength {
                    HStack {
                        Spacer()
                        Text("\(text.count)/\(maxLength)")
                            .font(Font.setFontRegular())
                            .foregroundStyle(text.count >= maxLength ? .red : Color.theme.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }
            }
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
