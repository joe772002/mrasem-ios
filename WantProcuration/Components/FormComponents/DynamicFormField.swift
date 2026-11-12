import SwiftUI

// MARK: - Dynamic Form Field
struct DynamicFormField: View {
    let field: FormField
    let onValueChange: (Any, Any?) -> Void
    
    @State private var textValue: String = ""
    @State private var numberValue: String = ""
    @State private var decimalValue: String = ""
    @State private var pickerValue: Any?
    @State private var dateValue: Date = Date()
    @State private var toggleValue: Bool = false
    @State private var fileData: Data = Data()
    @State private var fileURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                switch field.type {
                case .text:
                    FormTextFieldRow(
                        title: field.placeholder ?? field.title.localized(),
                        placeholder: field.placeholder ?? "",
                        text: $textValue,
                        required: field.required,
                        maxLength: field.maxLength
                    ).onChange(of: textValue) { oldValue, newValue in
                        if let max = field.maxLength, newValue.count > max {
                            textValue = String(newValue.prefix(max))
                            onValueChange(textValue, oldValue)
                        } else {
                            onValueChange(newValue, oldValue)
                        }
                    }
                    
                case .number:
                    FormTextFieldRow(
                        title: field.placeholder ?? field.title.localized(),
                        placeholder: field.placeholder ?? "",
                        text: $numberValue,
                        required: field.required,
                        keyboardType: .decimalPad,
                        maxLength: field.maxLength
                    ).onChange(of: numberValue) { oldValue, newValue in
//                        if let number = Double(newValue) {
//                            onValueChange(number, oldValue)
//                        } else if let number = Int(newValue) {
//                            onValueChange(number, oldValue)
//                        }else {
                            onValueChange(newValue, oldValue)
//                        }
                    }
                    
                case .decimal:
                    FormTextFieldRow(
                        title: field.placeholder ?? field.title.localized(),
                        placeholder: field.placeholder ?? "",
                        text: $decimalValue,
                        required: field.required,
                        keyboardType: .decimalPad,
                        maxLength: field.maxLength
                    ).onChange(of: decimalValue) { oldValue, newValue in
//                        if let number = Int(newValue) {
//                            onValueChange(number, oldValue)
//                        }else {
                            onValueChange(newValue, oldValue)
//                        }
                    }
                    
                case .picker:
                    PickerFieldView(
                        field: field,
                        pickerValue: $pickerValue,
                        onValueChange: onValueChange
                    )
                    
                case .date:
                    FormDatePickerRow(
                        title: field.title.localized(),
                        date: $dateValue,
                        required: field.required
                    ).onChange(of: dateValue) { oldValue, newValue in
                        onValueChange(newValue, oldValue)
                    }
                    
                case .toggle:
                    FormToggleRow(
                        title: field.title.localized(),
                        description: field.placeholder ?? "",
                        isOn: $toggleValue
                    ).onChange(of: toggleValue) { oldValue, newValue in
                        onValueChange(newValue, oldValue)
                    }
                    
                case .multiline:
                    FormMultilineTextFieldRow(
                        title: field.title.localized(),
                        placeholder: field.placeholder ?? "",
                        text: $textValue,
                        required: field.required,
                        maxLength: field.maxLength,
                        minHeight: 100
                    ).onChange(of: textValue) { oldValue, newValue in
                        if let max = field.maxLength, newValue.count > max {
                            textValue = String(newValue.prefix(max))
                            onValueChange(textValue, oldValue)
                        } else {
                            onValueChange(newValue, oldValue)
                        }
                    }
                }
            }
        }
        .onAppear {
            switch field.type {
            case .text, .multiline:
                textValue = field.value as? String ?? ""
            case .number:
                if let stringVal = field.value as? String {
                    // e.g. the national ID (kept as text so leading digits are not lost)
                    numberValue = stringVal
                } else if let doubleVal = field.value as? Double {
                    numberValue = String(doubleVal)
                } else {
                    numberValue = ""
                }
            case .decimal:
                if let intVal = field.value as? Int {
                    decimalValue = String(intVal)
                } else {
                    decimalValue = ""
                }
            case .picker:
                pickerValue = field.value
            case .date:
                dateValue = field.value as? Date ?? Date()
            case .toggle:
                toggleValue = field.value as? Bool ?? false
            }
        }
    }
}

// MARK: - Picker Field View Helper
private struct PickerFieldView: View {
    let field: FormField
    @Binding var pickerValue: Any?
    let onValueChange: (Any, Any?) -> Void
    
    var body: some View {
        if let options = field.options {
            if let stringOptions = options as? [String] {
                StringPickerView(
                    field: field,
                    options: stringOptions,
                    pickerValue: $pickerValue,
                    onValueChange: onValueChange
                )
            } else if let categoryOptions = options as? [TransactionCategory] {
                TransactionCategoryPickerView(
                    field: field,
                    options: categoryOptions,
                    pickerValue: $pickerValue,
                    onValueChange: onValueChange
                )
            } else if let typeOptions = options as? [TransactionType] {
                TransactionTypePickerView(
                    field: field,
                    options: typeOptions,
                    pickerValue: $pickerValue,
                    onValueChange: onValueChange
                )
            } else if let dateOptions = options as? [ReservationDate] {
                ReservationDatePickerView(
                    field: field,
                    options: dateOptions,
                    pickerValue: $pickerValue,
                    onValueChange: onValueChange
                )
            } else if let periodOptions = options as? [ReservePeriod] {
                ReservePeriodPickerView(
                    field: field,
                    options: periodOptions,
                    pickerValue: $pickerValue,
                    onValueChange: onValueChange
                )
            } else if let timeOptions = options as? [ReservationTime] {
                ReservationTimePickerView(
                    field: field,
                    options: timeOptions,
                    pickerValue: $pickerValue,
                    onValueChange: onValueChange
                )
            } else {
                Text("Unsupported picker type")
                    .foregroundColor(.red)
            }
        } else {
            Text("No options provided")
                .foregroundColor(.red)
        }
    }
}

// MARK: - String Picker
private struct StringPickerView: View {
    let field: FormField
    let options: [String]
    @Binding var pickerValue: Any?
    let onValueChange: (Any, Any?) -> Void
    
    var body: some View {
        let stringBinding = Binding<String?>(
            get: { pickerValue as? String },
            set: { newValue in
                let oldValue = pickerValue
                pickerValue = newValue
                onValueChange(newValue ?? "", oldValue)
            }
        )
        
        GenericFormPickerRow(
            title: field.title.localized(),
            selection: stringBinding,
            options: options,
            required: field.required
        )
    }
}

// MARK: - TransactionCategory Picker
private struct TransactionCategoryPickerView: View {
    let field: FormField
    let options: [TransactionCategory]
    @Binding var pickerValue: Any?
    let onValueChange: (Any, Any?) -> Void
    
    var body: some View {
        let categoryBinding = Binding<TransactionCategory?>(
            get: { pickerValue as? TransactionCategory },
            set: { newValue in
                let oldValue = pickerValue
                pickerValue = newValue
                onValueChange(newValue as Any, oldValue)
            }
        )
        
        GenericFormPickerRow(
            title: field.title.localized(),
            selection: categoryBinding,
            options: options,
            required: field.required,
            placeholder: field.placeholder ?? "Select".localized()
        )
    }
}

// MARK: - TransactionType Picker
private struct TransactionTypePickerView: View {
    let field: FormField
    let options: [TransactionType]
    @Binding var pickerValue: Any?
    let onValueChange: (Any, Any?) -> Void
    
    var body: some View {
        let typeBinding = Binding<TransactionType?>(
            get: { pickerValue as? TransactionType },
            set: { newValue in
                let oldValue = pickerValue
                pickerValue = newValue
                onValueChange(newValue as Any, oldValue)
            }
        )
        
        GenericFormPickerRow(
            title: field.title.localized(),
            selection: typeBinding,
            options: options,
            required: field.required,
            placeholder: field.placeholder ?? "select".localized()
        )
    }
}

// MARK: - ReservationDate Picker
private struct ReservationDatePickerView: View {
    let field: FormField
    let options: [ReservationDate]
    @Binding var pickerValue: Any?
    let onValueChange: (Any, Any?) -> Void
    
    var body: some View {
        let dateBinding = Binding<ReservationDate?>(
            get: { pickerValue as? ReservationDate },
            set: { newValue in
                let oldValue = pickerValue
                pickerValue = newValue
                onValueChange(newValue as Any, oldValue)
            }
        )
        
        GenericFormPickerRow(
            title: field.title.localized(),
            selection: dateBinding,
            options: options,
            required: field.required,
            placeholder: field.placeholder ?? "Select".localized()
        )
    }
}

// MARK: - ReservePeriod Picker
private struct ReservePeriodPickerView: View {
    let field: FormField
    let options: [ReservePeriod]
    @Binding var pickerValue: Any?
    let onValueChange: (Any, Any?) -> Void
    
    var body: some View {
        let periodBinding = Binding<ReservePeriod?>(
            get: { pickerValue as? ReservePeriod },
            set: { newValue in
                let oldValue = pickerValue
                pickerValue = newValue
                onValueChange(newValue as Any, oldValue)
            }
        )
        
        GenericFormPickerRow(
            title: field.title.localized(),
            selection: periodBinding,
            options: options,
            required: field.required,
            placeholder: field.placeholder ?? "Select".localized()
        )
    }
}

// MARK: - ReservationTime Picker (NEW)
private struct ReservationTimePickerView: View {
    let field: FormField
    let options: [ReservationTime]
    @Binding var pickerValue: Any?
    let onValueChange: (Any, Any?) -> Void
    
    var body: some View {
        let timeBinding = Binding<ReservationTime?>(
            get: { pickerValue as? ReservationTime },
            set: { newValue in
                let oldValue = pickerValue
                pickerValue = newValue
                onValueChange(newValue as Any, oldValue)
            }
        )
        
        GenericFormPickerRow(
            title: field.title.localized(),
            selection: timeBinding,
            options: options,
            required: field.required,
            placeholder: field.placeholder ?? "Select".localized()
        )
    }
}
