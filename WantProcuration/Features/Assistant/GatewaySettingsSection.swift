//
//  GatewaySettingsSection.swift
//  WantProcuration
//
//  Settings → «خادم المساعد الذكي (للتجربة)» (IOS_PORT_GUIDE.md §4.11).
//  The trycloudflare link changes whenever the gateway laptop restarts, so testers can change it from the app
//  without a new build. Shown in Debug builds; in Release after 7 taps on the «Version» row.
//

import SwiftUI

/// Whether the section is visible on this device.
enum GatewaySettingsAccess {
    static let unlockedKey = "ai_gateway.settings_unlocked"
    static let tapsToUnlock = 7

    static var isVisible: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: unlockedKey)
        #endif
    }

    static func unlock() {
        UserDefaults.standard.set(true, forKey: unlockedKey)
    }
}

struct GatewaySettingsSection: View {
    @State private var input = ""
    @State private var current = GatewayConfig.baseURL
    @State private var isDefault = GatewayConfig.isUsingDefault
    @State private var isTesting = false
    @State private var message: (text: String, isError: Bool)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("gateway_section".localized())
                .font(.setFontBold(size: 18))
                .foregroundColor(Color.theme.text)

            Text("gateway_hint".localized())
                .font(.setFontRegular(size: 13))
                .foregroundColor(Color.theme.themeGray)
                .fixedSize(horizontal: false, vertical: true)

            // Current link
            VStack(alignment: .leading, spacing: 4) {
                Text("gateway_current".localized() + (isDefault ? " " + "gateway_default_tag".localized() : ""))
                    .font(.setFontRegular(size: 12))
                    .foregroundColor(Color.theme.themeGray)
                Text(current.isEmpty ? "—" : current)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color.theme.text)
                    // One line: shrinks to fit instead of wrapping the link in two.
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .environment(\.layoutDirection, .leftToRight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.white1.opacity(0.5)))

            // New link (left-to-right)
            // verbatim: a plain string key is parsed as Markdown and the URL showed as a blue link.
            TextField(text: $input, prompt: Text(verbatim: "https://xxxx.trycloudflare.com")) { EmptyView() }
                .font(.system(size: 14, design: .monospaced))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .multilineTextAlignment(.leading)
                .environment(\.layoutDirection, .leftToRight)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.white1))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))

            HStack(spacing: 8) {
                Button {
                    Task { await testAndSave() }
                } label: {
                    HStack(spacing: 6) {
                        if isTesting { ProgressView().tint(.white) }
                        Text("gateway_test_save".localized())
                    }
                    .font(.setFontSemiBold(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.theme.themeBlue, in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isTesting || input.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    saveWithoutTest()
                } label: {
                    Text("gateway_save_anyway".localized())
                        .font(.setFont(size: 14))
                        .foregroundColor(Color.theme.themeBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.theme.themeBlue.opacity(0.5), lineWidth: 1))
                }
                .disabled(isTesting || input.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Button {
                GatewayConfig.resetToDefault()
                refresh()
                message = ("gateway_reset_done".localized(), false)
            } label: {
                Text("gateway_reset".localized())
                    .font(.setFont(size: 14))
                    .foregroundColor(Color.theme.themeBlue)
            }
            .disabled(isDefault || isTesting)

            if let message {
                Text(message.text)
                    .font(.setFontRegular(size: 13))
                    .foregroundColor(message.isError ? .red : .green)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 20)
        .onAppear { refresh() }
    }

    private func refresh() {
        current = GatewayConfig.baseURL
        isDefault = GatewayConfig.isUsingDefault
    }

    /// GET <url>/health; saves only when it answers. On failure the previous link stays.
    private func testAndSave() async {
        guard let url = GatewayConfig.normalize(input) else {
            message = ("gateway_invalid".localized(), true)
            return
        }
        isTesting = true
        defer { isTesting = false }
        if await GatewayClient.shared.checkHealth(of: url) {
            GatewayConfig.saveOverride(url)
            input = ""
            refresh()
            message = ("gateway_ok".localized(), false)
        } else {
            message = ("gateway_fail".localized(), true)
        }
    }

    private func saveWithoutTest() {
        guard let url = GatewayConfig.normalize(input) else {
            message = ("gateway_invalid".localized(), true)
            return
        }
        GatewayConfig.saveOverride(url)
        input = ""
        refresh()
        message = ("gateway_saved".localized(), false)
    }
}
