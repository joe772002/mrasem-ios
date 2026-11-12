//
//  AdminResourceDrafts.swift
//  Mrasem
//
//  Phase 15 — مسوّدات نماذج الموارد والأماكن والفريق. كل مسوّدة بتحتفظ بالسجل الأصلي (`base`)
//  عشان الحقول اللي النموذج مش بيعدّلها (الإحداثيات…) ما تضيعش.
//

import Foundation

struct DriverDraft: Equatable {
    var id = ""
    var name = ""
    var phone = ""
    var status: DriverStatus = .available
    private var isExisting = false

    init() {}

    init(_ record: DriverRecord) {
        id = record.id
        name = record.name
        phone = record.phone
        status = record.status
        isExisting = true
    }

    var isNew: Bool { !isExisting }

    func record() -> DriverRecord {
        DriverRecord(id: id, name: name, phone: phone.storeTrimmed, status: status)
    }
}

struct CarDraft: Equatable {
    var id = ""
    var type = ""
    var plate = ""
    var plateStyle: PlateStyle = .qatar
    var driverId: String?
    private var isExisting = false

    init() {}

    init(_ record: CarRecord) {
        id = record.id
        type = record.type
        plate = record.plate
        plateStyle = record.plateStyle
        driverId = record.driverId
        isExisting = true
    }

    var isNew: Bool { !isExisting }

    func record() -> CarRecord {
        CarRecord(id: id, type: type, plate: plate, plateStyle: plateStyle, driverId: driverId)
    }
}

struct EscortDraft: Equatable {
    var id = ""
    var name = ""
    var title = ""
    var phone = ""
    var meetingSpot = ""
    private var isExisting = false

    init() {}

    init(_ record: EscortRecord) {
        id = record.id
        name = record.name
        title = record.title
        phone = record.phone
        meetingSpot = record.meetingSpot
        isExisting = true
    }

    var isNew: Bool { !isExisting }

    func record() -> EscortRecord {
        EscortRecord(id: id, name: name, title: title.storeTrimmed, phone: phone.storeTrimmed,
                     meetingSpot: meetingSpot.storeTrimmed)
    }
}

struct PlaceDraft: Equatable {
    var id = ""
    var kind: PlaceKind = .attraction
    var mode: MissionMode = .inbound
    var name = ""
    var description = ""
    var minutes = "0"
    var durationHours = "0"
    var tag = ""
    var official = ""
    var building = ""
    var area = ""
    var entrance = ""
    var floor = ""
    var hall = ""
    var parking = ""
    var mapLabel = ""
    var breakfast = ""
    var phone = ""

    private var base: PlaceRecord?

    init() {}

    init(_ record: PlaceRecord) {
        id = record.id
        kind = record.kind
        mode = record.mode
        name = record.name
        description = record.description
        minutes = String(record.minutes)
        durationHours = Self.format(record.durationHours)
        tag = record.tag
        official = record.official
        building = record.building
        area = record.area
        entrance = record.entrance
        floor = record.floor
        hall = record.hall
        parking = record.parking
        mapLabel = record.mapLabel
        breakfast = record.breakfast
        phone = record.phone
        base = record
    }

    var isNew: Bool { base == nil }

    /// رقم غلط (مش فاضي ومش رقم) = قيمة سالبة، فالـ service يرفضه بـ `invalidTime`.
    func record() -> PlaceRecord {
        var record = base ?? PlaceRecord(
            id: "", kind: kind, mode: mode, name: "", description: "", minutes: 0, durationHours: 0, tag: "",
            official: "", building: "", area: "", entrance: "", floor: "", hall: "", parking: "",
            latitude: nil, longitude: nil, mapLabel: "", breakfast: "", phone: ""
        )
        record.id = id
        record.kind = kind
        record.mode = mode
        record.name = name
        record.description = description.storeTrimmed
        record.minutes = Self.int(minutes)
        record.durationHours = Self.double(durationHours)
        record.tag = tag.storeTrimmed
        record.official = official.storeTrimmed
        record.building = building.storeTrimmed
        record.area = area.storeTrimmed
        record.entrance = entrance.storeTrimmed
        record.floor = floor.storeTrimmed
        record.hall = hall.storeTrimmed
        record.parking = parking.storeTrimmed
        record.mapLabel = mapLabel.storeTrimmed
        record.breakfast = breakfast.storeTrimmed
        record.phone = phone.storeTrimmed
        return record
    }

    private static func int(_ text: String) -> Int {
        let value = text.storeLatinDigits
        return value.isEmpty ? 0 : (Int(value) ?? -1)
    }

    private static func double(_ text: String) -> Double {
        let value = text.storeLatinDigits
        return value.isEmpty ? 0 : (Double(value) ?? -1)
    }

    private static func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }
}

struct TeamUserDraft: Equatable {
    var id = ""
    var name = ""
    var role: TeamRole = .coordinator
    var phone = ""
    var email = ""
    private var isExisting = false

    init() {}

    init(_ record: TeamUserRecord) {
        id = record.id
        name = record.name
        role = record.role
        phone = record.phone
        email = record.email
        isExisting = true
    }

    var isNew: Bool { !isExisting }

    func record() -> TeamUserRecord {
        TeamUserRecord(id: id, name: name, role: role, phone: phone.storeTrimmed, email: email.storeTrimmed)
    }
}

extension DriverDraft: Identifiable {}
extension CarDraft: Identifiable {}
extension EscortDraft: Identifiable {}
extension PlaceDraft: Identifiable {}
extension TeamUserDraft: Identifiable {}
