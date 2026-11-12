//
//  ReservationPickerModels.swift
//  WantProcuration
//
//  Models backing the generic pickers in `DynamicFormField`.
//
//  Moved here from `Views/Reservation/Model/` in Phase 0: the booking screens that
//  owned them are gone (proxy code), but the reusable form components stay, and
//  these are the types they render.
//

import Foundation

// MARK: - TransactionCategory

struct TransactionCategory: Codable, Identifiable, Pickable {
    let id = UUID()
    var code: String?
    var desc: String?

    enum CodingKeys: String, CodingKey {
        case code
        case desc
    }

    var displayName: String {
        return desc ?? ""
    }

    init(code: String? = nil, desc: String? = nil) {
        self.code = code
        self.desc = desc
    }

    init() {}
}

// MARK: - TransactionType

struct TransactionType: Codable, Identifiable, Pickable {
    let id = UUID()
    var code: String?
    var desc: String?

    enum CodingKeys: String, CodingKey {
        case code
        case desc
    }

    var displayName: String {
        return desc ?? ""
    }

    init(code: String? = nil, desc: String? = nil) {
        self.code = code
        self.desc = desc
    }

    init() {}
}

// MARK: - ReservationDate

struct ReservationDate: Codable, Identifiable, Pickable {
    var id = UUID()
    let dateReserved: String
    let reservePeriods: [ReservePeriod]?
    let reservationTime: [ReservationTime]?

    enum CodingKeys: String, CodingKey {
        case dateReserved = "datereserved"
        case reservePeriods = "reservePeriods"
        case reservationTime = "reservationTime"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateReserved = try container.decode(String.self, forKey: .dateReserved)
        reservePeriods = try container.decodeIfPresent([ReservePeriod].self, forKey: .reservePeriods)
        reservationTime = try container.decodeIfPresent([ReservationTime].self, forKey: .reservationTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateReserved, forKey: .dateReserved)
        try container.encodeIfPresent(reservePeriods, forKey: .reservePeriods)
        try container.encodeIfPresent(reservationTime, forKey: .reservationTime)
    }

    var displayName: String {
        return dateReserved
    }

    init(id: UUID = UUID(), dateReserved: String, reservePeriods: [ReservePeriod]? = nil, reservationTime: [ReservationTime]? = nil) {
        self.id = id
        self.dateReserved = dateReserved
        self.reservePeriods = reservePeriods
        self.reservationTime = reservationTime
    }
}

// MARK: - ReservePeriod

struct ReservePeriod: Codable, Identifiable, Pickable {
    var id = UUID()
    let timePeriod: String
    let timePeriodCode: String

    var displayName: String {
        return TimeDisplay.twelveHour(timePeriod)
    }

    enum CodingKeys: String, CodingKey {
        case timePeriod
        case timePeriodCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timePeriod = try container.decode(String.self, forKey: .timePeriod)
        timePeriodCode = try container.decode(String.self, forKey: .timePeriodCode)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timePeriod, forKey: .timePeriod)
        try container.encode(timePeriodCode, forKey: .timePeriodCode)
    }

    init(timePeriod: String, timePeriodCode: String) {
        self.timePeriod = timePeriod
        self.timePeriodCode = timePeriodCode
    }
}

// MARK: - ReservationTime

struct ReservationTime: Codable, Identifiable, Pickable {
    var id = UUID()
    let reserveTime: String

    var displayName: String {
        return TimeDisplay.twelveHour(reserveTime)
    }

    enum CodingKeys: String, CodingKey {
        case reserveTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reserveTime = try container.decode(String.self, forKey: .reserveTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reserveTime, forKey: .reserveTime)
    }

    init(reserveTime: String) {
        self.reserveTime = reserveTime
    }
}
