//
//  FormField.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 05/10/2025.
//

import Foundation
struct FormField: Identifiable {
    let id: String
    let title: String
    let type: FieldType
    let placeholder: String?
    let hint: String?
    let required: Bool
    var value: Any?
    var options: [Any]? // Changed to Any to support generic types
    var validationRule: ValidationRule?
    var maxLength: Int?
    var data: Data?
    
    enum FieldType: String {
        case text
        case number
        case decimal
        case picker
        case date
        case toggle
        case multiline
      
    }
    
    // Helper to get typed options
    func getOptions<T: Pickable>() -> [T]? {
        return options as? [T]
    }
    
    func validateField() -> String? {
        if self.required {
            if let stringValue = value as? String, stringValue.isEmpty {
                return "\(self.title) " + "isRequired".localized()
            }
            if value == nil {
                return "\(self.title) " + "isRequired".localized()
            }
        }
        
        if let rule = self.validationRule {
            if let pattern = rule.pattern, let stringValue = value as? String {
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: stringValue.utf16.count)
                if regex?.firstMatch(in: stringValue, range: range) == nil {
                    return "\(self.title) " + "formatIsInvalid".localized()
                }
            }
            
            if let stringValue = value as? String {
                if let minLength = rule.minLength, stringValue.count < minLength {
                    return "\(self.title) " + "mustBeAtLeast".localized() + " \(minLength) " + "characters".localized()
                }
                if let maxLength = rule.maxLength, stringValue.count > maxLength {
                    return "\(self.title) " + "mustNotExceed".localized() + " \(maxLength) " + "characters".localized()
                }
            }
            
            if let numValue = value as? Double {
                if let minValue = rule.minValue, numValue < minValue {
                    return "\(self.title) " + "mustBeAtLeast".localized() + " \(minValue)"
                }
                if let maxValue = rule.maxValue, numValue > maxValue {
                    return "\(self.title)  " + "mustNotExceed".localized() + " \(maxValue)"
                }
            }
            
            if let customValidator = rule.customValidator {
                if !customValidator(value) {
                    return "\(self.title) " + "isInvalid".localized()
                }
            }
        }
        
        return nil
    }
}
