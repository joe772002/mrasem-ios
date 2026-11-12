//
//  FormDatePickerRow.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 08/10/2025.
//


import SwiftUI
// MARK: - Form Date Picker Row
struct FormDatePickerRow: View {
    @Environment(\.appManager) var appManager
    let title: String
    @Binding var date: Date
    let required: Bool
    let displayedComponents: DatePickerComponents
    @State private var showPicker = false
    
    init(
        title: String,
        date: Binding<Date>,
        required: Bool = false,
        displayedComponents: DatePickerComponents = [.date]
    ) {
        self.title = title
        self._date = date
        self.required = required
        self.displayedComponents = displayedComponents
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        if displayedComponents == .date {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        } else if displayedComponents == .hourAndMinute {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        }
        return formatter
    }
    
    var body: some View {
        FormRow(title: title, required: required) {
            Button {
                showPicker = true
            } label: {
                HStack {
                    Text(dateFormatter.string(from: date))
                        .font(Font.setFontRegular())
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.theme.secondaryText)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(height: 50)
                .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPicker) {
                NavigationStack {
                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: displayedComponents
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
                .environment(\.locale, appManager.locale)
                .environment(\.layoutDirection, appManager.layoutDirection)
            }
        }
    }
}
