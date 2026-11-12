//
//  FormToggleRow.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 08/10/2025.
//

import SwiftUI
// MARK: - Form Toggle Row
struct FormToggleRow: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    let required: Bool
    
    init(
        title: String,
        description: String? = nil,
        isOn: Binding<Bool>,
        required: Bool = false
    ) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.required = required
    }
    
    var body: some View {
        FormRow(title: title, required: required) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let description = description {
                        Text(description)
                            .font(Font.setFontRegular())
                            .foregroundStyle(Color.theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            }
        }
    }
}
