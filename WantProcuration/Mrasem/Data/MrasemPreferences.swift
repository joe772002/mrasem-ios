//
//  MrasemPreferences.swift
//  Mrasem
//
//  Mirrors Android: data/local/MrasemPreferences.kt + MrasemPreferencesImpl.kt
//

import Foundation

/// الحفظ الدائم الوحيد في مراسم: آخر تاب للضيف (قاعدة C7).
protocol MrasemPreferences: AnyObject {
    var lastGuestTab: GuestTab? { get }
    func saveGuestTab(_ tab: GuestTab)
}

/// تنفيذ على `UserDefaults` — مفاتيح `mrasem_*` (قاعدة C7).
nonisolated final class UserDefaultsMrasemPreferences: MrasemPreferences {
    private enum Keys {
        static let guestTab = "mrasem_guest_tab"
        static let teamTab = "mrasem_team_tab"
        static let mode = "mrasem_mode"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastGuestTab: GuestTab? {
        defaults.string(forKey: Keys.guestTab).flatMap(GuestTab.init(rawValue:))
    }

    var lastTeamTab: TeamTab? {
        defaults.string(forKey: Keys.teamTab).flatMap(TeamTab.init(rawValue:))
    }

    var mode: MissionMode? {
        defaults.string(forKey: Keys.mode).flatMap(MissionMode.init(rawValue:))
    }

    func saveGuestTab(_ tab: GuestTab) {
        defaults.set(tab.rawValue, forKey: Keys.guestTab)
    }

    func saveTeamTab(_ tab: TeamTab) {
        defaults.set(tab.rawValue, forKey: Keys.teamTab)
    }

    func saveMode(_ mode: MissionMode) {
        defaults.set(mode.rawValue, forKey: Keys.mode)
    }
}
