//
//  ValidationRule.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 05/10/2025.
//

struct ValidationRule {
    let pattern: String?
    let minLength: Int?
    let maxLength: Int?
    let minValue: Double?
    let maxValue: Double?
    let customValidator: ((Any?) -> Bool)?
    
    static var emailValidationRule : ValidationRule {
        return ValidationRule(
            pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
            minLength: nil,
            maxLength: nil,
            minValue: nil,
            maxValue: nil,
            customValidator: { value in
                guard let email = value as? String else { return false }
                
                // Check if email ends with approved domains
                let approvedDomains = ["gov.om", "mtcit.gov.om", ".com", ".net"]
                return approvedDomains.contains { email.lowercased().hasSuffix($0) }
            }
        )
    }
    
    static var nationalIdValidationRule : ValidationRule {
       return ValidationRule(
                pattern: "^[0-9]{8}$",
                minLength: 8,
                maxLength: 8,
                minValue: nil,
                maxValue: nil,
                customValidator: { value in
                    guard let nationalId = value as? String else { return false }
                    
                    // Example: Check if ID is not in blacklist
                    let blacklistedIds = ["00000000", "11111111", "99999999"]
                    if blacklistedIds.contains(nationalId) {
                        return false
                    }
                    
                    // Example: Calculate checksum (simplified)
                    let digits = nationalId.compactMap { $0.wholeNumberValue }
                    guard digits.count == 8 else { return false }
                    
                    let sum = digits.reduce(0, +)
                    let checkDigit = digits.last ?? 0
                    
                    // Simplified checksum validation
                    return (sum % 10) == checkDigit
                }
            )
    }
}
