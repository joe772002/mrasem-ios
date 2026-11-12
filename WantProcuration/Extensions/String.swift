//
//  String.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//
import Foundation
import SwiftUI
// MARK: - String Extensions
extension String {
    func localized(comment: String = "") -> String {
        let currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "ar"
        let bundle = Bundle.bundle(for: currentLanguage)
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, range: range) != nil
    }
    
    var isValidPhoneNumber: Bool {
        let pattern = "^(\\+968)?[0-9]{8}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, range: range) != nil
    }
    
    var isValidNationalId: Bool {
        let pattern = "^[0-9]{8}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, range: range) != nil
    }
    
    
    
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
 
}
extension String: Pickable {
    public var id: String { self }
    public var displayName: String { self }
}
