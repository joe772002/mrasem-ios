//
//  MTCITApp.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//

import SwiftUI
import SwiftfulRouting
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
@main
struct WantProcurationApp: App {
    @State private var showLaunchScreen = true
    @StateObject var appManager = AppManager()
    
    init() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [
            .font: UIFont(name: "Cairo-SemiBold", size: 18)!,
            .foregroundColor: UIColor(named: "gray0") ?? .label
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFont(name: "Cairo-SemiBold", size: 26)!,
            .foregroundColor: UIColor(named: "gray0") ?? .label
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Cairo-Light", size: 14) ?? UIFont.systemFont(ofSize: 16)
        ]
        UISegmentedControl.appearance().setTitleTextAttributes(attributes, for: .normal)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                RouterView { _ in
                    HomeScreenView(appManager: appManager)
                        .environment(\.locale, appManager.locale)
                        .environment(\.layoutDirection, appManager.layoutDirection)
                        .modifier(IntentRoutingModifier(appManager: appManager)) // Siri / App Intents navigation
                }
                
                if showLaunchScreen {
                    LaunchScreen(onLoadingComplete: {
                        // Wait a bit for better UX, then dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showLaunchScreen = false
                            }
                        }
                    })
                }
            }
        }
    }
}
