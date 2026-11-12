//
//  WantProcurationApp.swift
//  Mrasem
//
//  Single entry point of the Mrasem app.
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/activities/LandingActivity.kt
//
//  Shows the Mrasem splash, then the Phase 0 placeholder. All data is local;
//  there is no network or startup work.
//

import SwiftUI
import UIKit
import SwiftfulRouting
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager

@main
struct WantProcurationApp: App {
    @StateObject private var appManager = AppManager()

    init() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardToolbarManager.shared.isEnabled = true

        // No force-unwrap on the font: a missing Cairo file must not crash the app.
        let appearance = UINavigationBarAppearance()
        if let titleFont = UIFont(name: "Cairo-SemiBold", size: 18) {
            appearance.titleTextAttributes = [
                .font: titleFont,
                .foregroundColor: UIColor(named: "gray0") ?? .label
            ]
        }
        if let largeTitleFont = UIFont(name: "Cairo-SemiBold", size: 26) {
            appearance.largeTitleTextAttributes = [
                .font: largeTitleFont,
                .foregroundColor: UIColor(named: "gray0") ?? .label
            ]
        }
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            // One router for the whole app (rule A7).
            // Mrasem is Arabic / RTL only (decision #4).
            RouterView { _ in
                MrasemRootView()
                    .environment(\.locale, Locale(identifier: "ar"))
                    .environment(\.layoutDirection, .rightToLeft)
                    .environmentObject(appManager)
            }
        }
    }
}

/// Root of the Mrasem app: splash first, then the start destination.
private struct MrasemRootView: View {
    @State private var isContentVisible = false

    var body: some View {
        ZStack {
            // Solid background so the splash transition never flashes through.
            MrasemBrand.maroon
                .ignoresSafeArea()

            if isContentVisible {
                MrasemPlaceholderScreen()
                    .transition(.opacity)
            } else {
                MrasemSplash()
                    .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeOut(duration: 0.4)) {
                isContentVisible = true
            }
        }
    }
}
