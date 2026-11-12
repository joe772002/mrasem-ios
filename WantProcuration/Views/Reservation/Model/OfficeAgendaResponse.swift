//
//  OfficeAgendaResponse.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import Foundation

// MARK: - OfficeAgendaResponse
struct OfficeAgendaResponse: Codable {
    // Only `officeAgendaData` is required. The other fields are optional because the API
    // does not always send them (e.g. office 9002 returns no channelRequestId / vipFlag),
    // and a missing field used to fail the whole agenda (no reservation dates).
    let type: String?
    let responseStatus: String?
    let responseStatusDesc: String?
    let channelRequestId: String?
    let correlationId: String?
    let officeAgendaData: OfficeAgendaData
    let originatingChannel: Int?
    let originatingUserIdentifier: String?
    let originatingUserType: Int?
    /// "1" or "4" = VIP office (exact time). Missing = regular office (periods).
    let vipFlag: String?
}

// MARK: - OfficeAgendaData
struct OfficeAgendaData: Codable {
    let reservationDate: [ReservationDate]
}

// MARK: - ReservationDate
struct ReservationDate: Codable, Identifiable, Pickable {
    var id = UUID()
    let dateReserved: String
    let reservePeriods: [ReservePeriod]?
    let reservationTime: [ReservationTime]?
    
    enum CodingKeys: String, CodingKey {
        case dateReserved = "datereserved"
        case reservePeriods = "reservePeriods"  // First JSON uses this
        case reservationTime = "reservationTime" // Second JSON uses this
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
    init (reserveTime: String) {
        self.reserveTime = reserveTime
    }

}
