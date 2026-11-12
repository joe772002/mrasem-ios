//
//  DeviceIdentity.swift
//  WantProcuration
//
//  One stable device id for the whole app (IOS_PORT_GUIDE.md §4.10):
//  - sent to the AI Gateway as "X-Device-Id" on every POST /chat (the gateway keeps a fair daily share per device
//    and stores only a salted fingerprint of it),
//  - sent to the booking API as `mobileSerialNum` (same value, like Android's ANDROID_ID).
//  It is created once from identifierForVendor and kept in the Keychain, so it survives reinstalling the app.
//

import Foundation
import UIKit
import Security
import CryptoKit

enum DeviceIdentity {
    private static let service = "WantProcuration.deviceId"
    private static let account = "device"
    private static var cached: String?

    /// The device id (never empty).
    static var id: String {
        if let cached { return cached }
        if let stored = readKeychain(), !stored.isEmpty {
            cached = stored
            return stored
        }
        let fresh = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        saveKeychain(fresh)
        cached = fresh
        return fresh
    }

    // MARK: Gateway headers

    /// "X-Device-Id", plus "X-App-Timestamp" / "X-App-Signature" when a signing secret is configured
    /// (APP_SIGNING_SECRET in Config/Secrets.xcconfig → Info.plist "AppSigningSecret").
    static func gatewayHeaders(now: Date = Date()) -> [String: String] {
        let deviceId = id
        var headers = ["X-Device-Id": deviceId]
        let secret = (Bundle.main.object(forInfoDictionaryKey: "AppSigningSecret") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // An unresolved "$(...)" means the build setting is missing: treat as no secret.
        if !secret.isEmpty, !secret.hasPrefix("$(") {
            let timestamp = String(Int(now.timeIntervalSince1970))
            headers["X-App-Timestamp"] = timestamp
            headers["X-App-Signature"] = signature(secret: secret, message: "\(deviceId).\(timestamp)")
        }
        return headers
    }

    /// hex(HMAC-SHA256(secret, message))
    static func signature(secret: String, message: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Keychain

    private static func baseQuery() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private static func readKeychain() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveKeychain(_ value: String) {
        SecItemDelete(baseQuery() as CFDictionary)
        var query = baseQuery()
        query[kSecValueData as String] = Data(value.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Logger.warning("DeviceIdentity: could not save to Keychain (\(status))")
        }
    }
}
