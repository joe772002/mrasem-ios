//
//  UserDefaults.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//
import Foundation
/// MARK: - UserDefaults Extensions
extension UserDefaults {
    enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let notificationsEnabled = "notificationsEnabled"
        static let biometricEnabled = "biometricEnabled"
        static let language = "preferredLanguage"
    }
    
    var hasLaunchedBefore: Bool {
        get { bool(forKey: Keys.hasLaunchedBefore) }
        set { set(newValue, forKey: Keys.hasLaunchedBefore) }
    }
    
    var notificationsEnabled: Bool {
        get { bool(forKey: Keys.notificationsEnabled) }
        set { set(newValue, forKey: Keys.notificationsEnabled) }
    }
    
    var biometricEnabled: Bool {
        get { bool(forKey: Keys.biometricEnabled) }
        set { set(newValue, forKey: Keys.biometricEnabled) }
    }
}

