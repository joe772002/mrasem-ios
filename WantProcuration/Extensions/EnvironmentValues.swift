//
//  EnvironmentValues.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 08/10/2025.
//

import SwiftUI

extension EnvironmentValues {
    private struct AppManagerKey: EnvironmentKey {
        static let defaultValue = AppManager()
    }
    var appManager: AppManager {
        get { self[AppManagerKey.self] }
        set { self[AppManagerKey.self] = newValue }
    }
}
