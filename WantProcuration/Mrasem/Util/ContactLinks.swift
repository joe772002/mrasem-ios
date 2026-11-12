//
//  ContactLinks.swift
//  Mrasem
//
//  Mirrors Android: util/ContactLinks.kt
//

import Foundation

/// روابط الاتصال والخرائط (دوال نقيّة قابلة للاختبار).
enum ContactLinks {
    /// `tel:` من غير مسافات، مع الإبقاء على علامة + والأرقام.
    static func tel(_ phone: String) -> String {
        "tel:" + phone.filter { !$0.isWhitespace }
    }

    /// `https://wa.me/` بالأرقام فقط (من غير + أو مسافات).
    static func whatsApp(_ phone: String) -> String {
        "https://wa.me/" + phone.filter { $0.isNumber }
    }

    static func maps(lat: Double, lng: Double) -> String {
        "https://www.google.com/maps/search/?api=1&query=\(lat),\(lng)"
    }
}
