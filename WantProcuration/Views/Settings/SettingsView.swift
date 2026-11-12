//
//  SettingsView.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 21/10/2025.
//

import SwiftUI
import SwiftfulRouting

enum AppLanguage: String, CaseIterable, Identifiable {
//    case english = "en"
    case arabic = "ar"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
//        case .english: return "English"
        case .arabic: return "العربية"
        }
        
    }
    
    var flag: String {
        switch self {
//        case .english: return "🇺🇸"
        case .arabic: return "🇪🇬"
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var appManager: AppManager
    @Environment(\.router) var router
    /// Gateway link section (§4.11): always in Debug; in Release after 7 taps on «Version».
    @State private var showGatewaySection = GatewaySettingsAccess.isVisible
    @State private var versionTaps = 0
    private var appVersion: String {
           let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
//           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
           return "\(version)"
       }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Language Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Language".localized())
                        .font(.setFontBold(size: 18))
                        .foregroundColor(Color.theme.text)
                    
                    ForEach(AppLanguage.allCases) { language in
                        LanguageRow(
                            language: language,
                            isSelected: appManager.currentLanguage == language.rawValue
                        ) {
                            withAnimation {
                                appManager.setLanguage(language.rawValue)
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
                
                // Theme Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance".localized())
                        .font(.setFontBold(size: 18))
                        .foregroundColor(Color.theme.text)
                    
                    ThemeToggleRow(appManager : appManager,action: { isDark in
                        appManager.isDarkMode = isDark
                    })
                   
                }
                .padding(.vertical, 20)
                
                // About Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("About".localized())
                        .font(.setFontBold(size: 18))
                        .foregroundColor(Color.theme.text)
                    
                    HStack {
                        Text("Version".localized())
                            .foregroundColor(Color.theme.text)
                            .font(.setFont())
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(Color.theme.secondaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.white1.opacity(0.5))
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !showGatewaySection else { return }
                        versionTaps += 1
                        if versionTaps >= GatewaySettingsAccess.tapsToUnlock {
                            GatewaySettingsAccess.unlock()   // stays visible on this device
                            withAnimation { showGatewaySection = true }
                        }
                    }
                }
                .padding(.vertical, 20)

                if showGatewaySection {
                    GatewaySettingsSection()
                    BookingTestSection(isRTL: appManager.isRTL)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color.theme.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done".localized()) {
                    router.dismissScreen()
                }
                .font(.setFont())
                .foregroundColor(Color.theme.accent)
            }
        }
        .navigationTitle("Settings".localized())
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.layoutDirection, appManager.layoutDirection)
        .preferredColorScheme(appManager.isDarkMode ? .dark : .light)
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(language.flag)
                    .font(.title2)
                
                Text(language.displayName)
                    .foregroundColor(Color.theme.text)
                    .font(.setFont())
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.theme.accent)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.theme.accent.opacity(0.1) : Color.theme.white1.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.theme.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Toggle Row
struct ThemeToggleRow: View {
    @ObservedObject var appManager: AppManager
    let action: (_ isDark : Bool) -> Void
    var body: some View {
        HStack(spacing: 16) {
            // Light Mode Button
            ThemeButton(
                icon: "sun.max.fill",
                title: "Light".localized(),
                iconColor: .orange,
                isSelected: !appManager.isDarkMode
            ) {
                withAnimation {
                    action(false)
                }
            }
            
            // Dark Mode Button
            ThemeButton(
                icon: "moon.fill",
                title: "Dark".localized(),
                iconColor: Color.theme.accent,
                isSelected: appManager.isDarkMode
            ) {
                withAnimation {
                    action(true)
                }
            }
        }
    }
}

// MARK: - Theme Button
struct ThemeButton: View {
    let icon: String
    let title: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.theme.accent.opacity(0.2) : Color.theme.secondaryText.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Color.theme.accent : iconColor.opacity(0.6))
                }
                
                Text(title)
                    .font(.setFont())
                    .foregroundColor(isSelected ? Color.theme.text : Color.theme.secondaryText)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.theme.accent.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.theme.accent : Color.theme.secondaryText.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    
    RouterView { _ in
        SettingsView(appManager: AppManager())
        
    }
}
