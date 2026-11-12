//
//  AppManager.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 05/10/2025.
//

import Foundation
import SwiftUI
import Combine

class AppManager : ObservableObject {
    @Published var isDarkMode: Bool = true {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    @Published var currentLanguage: String = "ar" {
        didSet {
            updateLocale()
        }
    }
    
    @Published var locale: Locale = Locale(identifier: "ar")
    @Published var isRTL: Bool = true
    @Published var layoutDirection: LayoutDirection = .rightToLeft
    
    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "ar"
        updateLocale()
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "selectedLanguage")
        UserDefaults.standard.synchronize()
    }
    
    private func updateLocale() {
        locale = Locale(identifier: currentLanguage)
        isRTL = ["ar", "he", "fa", "ur"].contains(currentLanguage)
        layoutDirection = isRTL ? .rightToLeft : .leftToRight
    }
}
