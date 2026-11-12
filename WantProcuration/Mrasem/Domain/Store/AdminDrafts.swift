//
//  AdminDrafts.swift
//  Mrasem
//
//  Phase 14 — مسوّدات نماذج الأدمن (وفد، عضو، فقرة). المسوّدة بتشيل الحقول المعروضة بس،
//  و`record()` بيرجّع السجل كامل بالحقول اللي النموذج مش بيعدّلها (المنسقين، الوجهة…) زي ما كانت.
//

import Foundation

extension StoreValidationError {
    var messageKey: String {
        switch self {
        case .emptyName: return "mrasem_admin_error_name"
        case .invalidDate: return "mrasem_admin_error_date"
        case .invalidTime: return "mrasem_admin_error_time"
        case .endBeforeStart: return "mrasem_admin_error_range"
        case .dateOutsideDelegation: return "mrasem_admin_error_outside"
        case .notFound: return "mrasem_admin_error_missing"
        case .lastAdmin: return "mrasem_admin_error_last_admin"
        }
    }
}

/// اختيار من قائمة: «بدون» (`id == nil`) أو سجل.
struct PickerOption: Equatable, Identifiable {
    let id: String?
    let label: String

    var key: String { id ?? "" }
}

nonisolated enum AdminOptions {
    static func hotels(_ db: MrasemDatabase, none: String) -> [PickerOption] {
        [PickerOption(id: nil, label: none)] + db.places.filter { $0.kind == .hotel }.map { PickerOption(id: $0.id, label: $0.name) }
    }

    static func venues(_ db: MrasemDatabase, none: String) -> [PickerOption] {
        [PickerOption(id: nil, label: none)] + db.places.filter { $0.kind != .hotel }.map { PickerOption(id: $0.id, label: $0.name) }
    }

    static func places(_ db: MrasemDatabase, none: String) -> [PickerOption] {
        [PickerOption(id: nil, label: none)] + db.places.map { PickerOption(id: $0.id, label: $0.name) }
    }

    static func escorts(_ db: MrasemDatabase, none: String) -> [PickerOption] {
        [PickerOption(id: nil, label: none)] + db.escorts.map { PickerOption(id: $0.id, label: $0.name) }
    }

    static func cars(_ db: MrasemDatabase, none: String) -> [PickerOption] {
        [PickerOption(id: nil, label: none)]
            + db.cars.map { PickerOption(id: $0.id, label: AdminDelegationDetailBuilder.carLabel($0) ?? $0.id) }
    }
}

struct DelegationDraft: Equatable {
    var id = ""
    var name = ""
    var mode: MissionMode = .inbound
    var host = ""
    var countryLabel = ""
    var start = ""
    var end = ""
    var hotelId: String?
    var venueId: String?
    var dress: DressCode = .formal
    var status: DelegationStatus = .draft

    private var base: DelegationRecord?

    init(start: String = "", end: String = "") {
        self.start = start
        self.end = end
    }

    init(_ record: DelegationRecord) {
        id = record.id
        name = record.name
        mode = record.mode
        host = record.host
        countryLabel = record.countryLabel
        start = record.start
        end = record.end
        hotelId = record.hotelId
        venueId = record.venueId
        dress = record.dress
        status = record.status
        base = record
    }

    var isNew: Bool { base == nil }

    func record() -> DelegationRecord {
        var record = base ?? DelegationRecord(
            id: "", name: "", mode: mode, host: "", countryLabel: "", destinationId: nil, start: "", end: "",
            hotelId: nil, venueId: nil, coordinatorIds: [], status: .draft, dress: .formal, nextMeeting: nil
        )
        record.id = id
        record.name = name
        record.mode = mode
        record.host = host.storeTrimmed
        record.countryLabel = countryLabel.storeTrimmed
        record.start = start.storeTrimmed
        record.end = end.storeTrimmed
        record.hotelId = hotelId
        record.venueId = venueId
        record.dress = dress
        record.status = status
        return record
    }
}

struct MemberDraft: Equatable {
    var id = ""
    var delegationId: String
    var name = ""
    var title = ""
    var room = ""
    var escortId: String?
    var carId: String?
    var isActivated = false
    var isHead = false

    private var base: MemberRecord?

    init(delegationId: String) {
        self.delegationId = delegationId
    }

    init(_ record: MemberRecord) {
        id = record.id
        delegationId = record.delegationId
        name = record.name
        title = record.title
        room = record.room
        escortId = record.escortId
        carId = record.carId
        isActivated = record.appStatus == .active
        isHead = record.isHead
        base = record
    }

    var isNew: Bool { base == nil }

    func record() -> MemberRecord {
        MemberRecord(
            id: id, delegationId: delegationId, name: name, title: title.storeTrimmed,
            escortId: escortId, carId: carId, room: room,
            appStatus: isActivated ? .active : .invited, isHead: isHead
        )
    }
}

struct ProgramDraft: Equatable {
    var id = ""
    var delegationId: String
    var date: String
    var time = "09:00"
    var endTime = "10:00"
    var title = ""
    var kind: ProgramItemKind = .official
    var placeId: String?
    var carId: String?
    var note = ""
    var isKey = false
    var notify = true

    private var base: ProgramItemRecord?

    init(delegationId: String, date: String, notify: Bool = true) {
        self.delegationId = delegationId
        self.date = date
        self.notify = notify
    }

    init(_ record: ProgramItemRecord, notify: Bool = true) {
        id = record.id
        delegationId = record.delegationId
        date = record.date
        time = record.time
        endTime = record.endTime ?? "10:00"
        title = record.title
        kind = record.kind
        placeId = record.placeId
        carId = record.carId
        note = record.note
        isKey = record.isKey
        self.notify = notify
        base = record
    }

    var isNew: Bool { base == nil }

    func record() -> ProgramItemRecord {
        ProgramItemRecord(
            id: id, delegationId: delegationId, date: date, time: time.storeTrimmed,
            endTime: kind == .free ? endTime.storeTrimmed : nil, title: title, kind: kind,
            placeId: placeId, note: note, carId: carId, isKey: isKey, isChanged: base?.isChanged ?? false
        )
    }
}
