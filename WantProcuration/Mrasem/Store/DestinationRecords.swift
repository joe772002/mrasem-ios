//
//  DestinationRecords.swift
//  Mrasem
//
//  Phase 11 — محتوى الوجهة المرجعي (الطقس، الخدمات، الأعراف، الزي…) والإعدادات.
//

import Foundation

struct LabelValueRecord: Codable, Equatable, Hashable {
    var label: String
    var value: String
}

struct ServiceAppRecord: Codable, Equatable, Hashable {
    var name: String
    var nameEn: String
    /// ARGB.
    var color: UInt32
    var description: String
    var url: String
}

struct ServiceCategoryRecord: Codable, Equatable, Hashable {
    var name: String
    var apps: [ServiceAppRecord]
}

struct DressSetRecord: Codable, Equatable, Hashable {
    var code: DressCode
    var title: String
    var men: [String]
    var women: [String]
}

/// محتوى الوجهة المرجعي اللي مش في البوابة (08 §3، القرار #4) — بيعدّله الأدمن.
struct DestinationRecord: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var mode: MissionMode
    var timeZone: String
    var currency: String
    var weather: String
    var emergency: [LabelValueRecord]
    var services: [ServiceCategoryRecord]
    var quickInfo: [LabelValueRecord]
    var customs: [String]
    var checklist: [String]
    var guides: [String]
    var dressSets: [DressSetRecord]
}

struct PreferencesRecord: Codable, Equatable {
    var notifyNewRequest = true
    var notifyConflict = true
    var notifyDaily = false
    var autoNotifyGuests = true
    var requireApproval = false
    var localNotifications = false
    var theme: ThemeChoice = .system
    var defaultMode: MissionMode = .inbound
}
