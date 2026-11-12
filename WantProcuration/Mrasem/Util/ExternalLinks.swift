//
//  ExternalLinks.swift
//  Mrasem
//
//  Mirrors Android: util/ExternalIntents.kt
//

import Foundation
import UIKit

/// فتح تطبيقات خارجية (اتصال، واتساب، خرائط، روابط). لو مفيش تطبيق يتعامل مع الرابط مفيش crash.
enum ExternalLinks {
    /// يفتح شاشة الاتصال بالرقم جاهزاً (`tel:` — من غير صلاحية).
    static func dial(_ phone: String) {
        open(ContactLinks.tel(phone))
    }

    static func whatsApp(_ phone: String) {
        open(ContactLinks.whatsApp(phone))
    }

    static func maps(lat: Double, lng: Double) {
        open(ContactLinks.maps(lat: lat, lng: lng))
    }

    static func open(_ url: String) {
        guard let target = URL(string: url) else { return }
        UIApplication.shared.open(target)
    }
}
