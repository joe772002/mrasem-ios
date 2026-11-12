//
//  AdminSettings.swift
//  Mrasem
//
//  Phase 15 — الإعدادات: الفريق والصلاحيات، التفضيلات (إشعارات / نشر / مظهر)، محتوى الوجهة، وإدارة البيانات.
//

import Foundation

struct AdminTeamRow: Equatable, Identifiable {
    let id: String
    let name: String
    let role: TeamRole
    let phone: String
    let email: String
    let delegationCount: Int
}

struct AdminDestinationRow: Equatable, Identifiable {
    let id: String
    let name: String
    let mode: MissionMode
}

struct AdminDataCounts: Equatable {
    let delegations: Int
    let members: Int
    let places: Int
    let requests: Int
}

struct AdminSettingsState: Equatable {
    let team: [AdminTeamRow]
    let preferences: PreferencesRecord
    let destinations: [AdminDestinationRow]
    let delegations: [PickerOption]
    let counts: AdminDataCounts

    static func make(_ db: MrasemDatabase) -> AdminSettingsState {
        AdminSettingsState(
            team: db.team.map { user in
                AdminTeamRow(
                    id: user.id, name: user.name, role: user.role, phone: user.phone, email: user.email,
                    delegationCount: db.delegations.count { $0.coordinatorIds.contains(user.id) }
                )
            },
            preferences: db.preferences,
            destinations: db.destinations.map { AdminDestinationRow(id: $0.id, name: $0.name, mode: $0.mode) },
            delegations: db.delegations.map { PickerOption(id: $0.id, label: $0.name) },
            counts: AdminDataCounts(
                delegations: db.delegations.count, members: db.members.count,
                places: db.places.count, requests: db.requests.count
            )
        )
    }
}

extension TeamRole {
    var adminLabelKey: String { "mrasem_admin_role_" + rawValue }
}

extension ThemeChoice {
    var adminLabelKey: String { "mrasem_admin_theme_" + rawValue }
}

extension PlaceKind {
    var adminLabelKey: String { "mrasem_admin_place_" + rawValue }
}

extension PlateStyle {
    var adminLabelKey: String { "mrasem_admin_plate_" + (self == .qatar ? "qatar" : "uk") }
}

extension DriverStatus {
    var adminLabelKey: String { "mrasem_admin_driver_" + rawValue }
}

/// تعديل محتوى الوجهة: الحقول النصية + القوائم (سطر لكل عنصر). باقي المحتوى (الخدمات، أطقم اللبس…) بيفضل زي ما هو.
struct DestinationDraft: Equatable, Identifiable {
    var id = ""
    var name = ""
    var mode: MissionMode = .inbound
    var timeZone = ""
    var currency = ""
    var weather = ""
    var customs = ""
    var checklist = ""
    var guides = ""
    /// «العنوان: القيمة» في كل سطر.
    var emergency = ""
    var quickInfo = ""

    private var base: DestinationRecord?

    init() {}

    init(_ record: DestinationRecord) {
        id = record.id
        name = record.name
        mode = record.mode
        timeZone = record.timeZone
        currency = record.currency
        weather = record.weather
        customs = record.customs.joined(separator: "\n")
        checklist = record.checklist.joined(separator: "\n")
        guides = record.guides.joined(separator: "\n")
        emergency = Self.join(record.emergency)
        quickInfo = Self.join(record.quickInfo)
        base = record
    }

    var isNew: Bool { base == nil }

    func record() -> DestinationRecord {
        var record = base ?? DestinationRecord(
            id: "", name: "", mode: mode, timeZone: "", currency: "", weather: "", emergency: [],
            services: [], quickInfo: [], customs: [], checklist: [], guides: [], dressSets: []
        )
        record.id = id
        record.name = name
        record.mode = mode
        record.timeZone = timeZone.storeTrimmed
        record.currency = currency.storeTrimmed
        record.weather = weather.storeTrimmed
        record.customs = Self.lines(customs)
        record.checklist = Self.lines(checklist)
        record.guides = Self.lines(guides)
        record.emergency = Self.pairs(emergency)
        record.quickInfo = Self.pairs(quickInfo)
        return record
    }

    static func lines(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).map { String($0).storeTrimmed }.filter { !$0.isEmpty }
    }

    static func pairs(_ text: String) -> [LabelValueRecord] {
        lines(text).map { line in
            guard let split = line.firstIndex(of: ":") else { return LabelValueRecord(label: line, value: "") }
            return LabelValueRecord(
                label: String(line[..<split]).storeTrimmed,
                value: String(line[line.index(after: split)...]).storeTrimmed
            )
        }
    }

    private static func join(_ pairs: [LabelValueRecord]) -> String {
        pairs.map { $0.value.isEmpty ? $0.label : $0.label + ": " + $0.value }.joined(separator: "\n")
    }
}
