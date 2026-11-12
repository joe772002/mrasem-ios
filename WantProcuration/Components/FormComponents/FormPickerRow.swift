//
//  FormPickerRow.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 08/10/2025.
//

import SwiftUI

// MARK: - Pickable Protocol
protocol Pickable: Identifiable, Hashable {
    var displayName: String { get }
}

// MARK: - Generic Form Picker Row
struct GenericFormPickerRow<T: Pickable>: View {
    @Environment(\.appManager) var appManager
    let title: String
    @Binding var selection: T?
    let options: [T]
    let required: Bool
    let placeholder: String
    @State private var showPicker = false
    @State private var searchText = ""
    
    init(
        title: String,
        selection: Binding<T?>,
        options: [T],
        required: Bool = false,
        placeholder: String = "Select".localized()
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.required = required
        self.placeholder = placeholder
    }
    
    var filteredOptions: [T] {
        if searchText.isEmpty {
            return options
        }
        return options.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        FormRow(title: title, required: required) {
            pickerButton
        }
    }
    
    // MARK: - Subviews
    private var pickerButton: some View {
        Button {
            showPicker = true
        } label: {
            buttonContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            pickerSheet
        }
    }
    
    private var buttonContent: some View {
        HStack {
            Text(selection?.displayName ?? placeholder)
                .font(Font.setFontRegular())
                .foregroundStyle(selection == nil ? .secondary : Color.theme.secondaryText)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundStyle(Color.theme.secondaryText)
                .font(.system(size: 14, weight: .semibold))
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
    
    private var pickerSheet: some View {
        NavigationStack {
            pickerList
                .scrollContentBackground(.hidden)
                .background(Color.theme.background)
                .searchable(text: $searchText, prompt: "Search")
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("إلغاء") {
                            showPicker = false
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
    }
    
    private var pickerList: some View {
        List {
            ForEach(filteredOptions) { option in
                optionRow(for: option)
            }
        }
    }
    
    private func optionRow(for option: T) -> some View {
        Button {
            selection = option
            showPicker = false
        } label: {
            HStack {
                Text(option.displayName)
                    .font(Font.setFontRegular())
                    .foregroundStyle(Color.theme.text)
                
                Spacer()
                
                if selection?.id == option.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .listRowBackground(Color.theme.cardBackground)
    }
}

#Preview {
    @Previewable @State var selectedCountry: String?
    let countries = [
        "United States",
        "United Kingdom",
        "Egypt"
    ]
    GenericFormPickerRow(title: "countries", selection: $selectedCountry, options: countries, required: true, placeholder: "select a country")
        .preferredColorScheme(.dark)
}
