//
//  GatewayBookingModels.swift
//  WantProcuration
//
//  Gateway models used by booking (IOS_PORT_GUIDE.md §2.5 – §2.8). Lenient like GatewayModels.swift.
//

import Foundation

// MARK: - Offices (/offices/recommend, /offices/alternatives)

struct GatewayOffice: Codable, Hashable {
    var id: String
    var name: String
    var address: String
    var gov: String
    var orgTypeDesc: String
    var isVip: Bool
    var distanceKm: Double
    /// yyyy-MM-dd
    var firstDate: String
    var vipFlag: String

    enum CodingKeys: String, CodingKey {
        case id, name, address, gov, orgTypeDesc, isVip, distanceKm, firstDate, vipFlag
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // The id may come as a string or a number.
        if let text = try? c.decodeIfPresent(String.self, forKey: .id) {
            id = text
        } else if let number = try? c.decodeIfPresent(Int.self, forKey: .id) {
            id = String(number)
        } else {
            id = ""
        }
        name = c.lenient(.name, "")
        address = c.lenient(.address, "")
        gov = c.lenient(.gov, "")
        orgTypeDesc = c.lenient(.orgTypeDesc, "")
        isVip = c.lenient(.isVip, false)
        distanceKm = c.lenient(.distanceKm, 0)
        firstDate = c.lenient(.firstDate, "")
        vipFlag = c.lenient(.vipFlag, "")
    }
}

struct OfficeDistance: Encodable {
    let id: String
    let distanceKm: Double
}

struct RecommendRequest: Encodable {
    let categoryCode: String
    let typeCode: String
    let offices: [OfficeDistance]
    /// true: the gateway answers from its index only (which offices offer the type); the app reads the free days
    /// (§2.5 — the cloud gateway can't reach the booking API).
    var clientAgenda: Bool = true
}

/// An office the gateway's index says offers the type; verify = the index doesn't know it: check its types too.
struct GatewayCandidate: Decodable, Hashable {
    var id: String
    var distanceKm: Double
    var verify: Bool

    enum CodingKeys: String, CodingKey { case id, distanceKm, verify }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try? c.decodeIfPresent(String.self, forKey: .id) {
            id = text
        } else if let number = try? c.decodeIfPresent(Int.self, forKey: .id) {
            id = String(number)
        } else {
            id = ""
        }
        distanceKm = c.lenient(.distanceKm, 0)
        verify = c.lenient(.verify, false)
    }
}

struct RecommendResponse: Decodable {
    var nearest: [GatewayOffice]
    var earliest: [GatewayOffice]
    var vip: [GatewayOffice]
    var indexReady: Bool
    /// "client-agenda": `candidates` to check here (older gateways send the three groups instead).
    var mode: String
    var candidates: [GatewayCandidate]

    enum CodingKeys: String, CodingKey { case nearest, earliest, vip, indexReady, mode, candidates }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nearest = c.lenient(.nearest, [])
        earliest = c.lenient(.earliest, [])
        vip = c.lenient(.vip, [])
        indexReady = c.lenient(.indexReady, false)
        mode = c.lenient(.mode, "")
        candidates = c.lenient(.candidates, [])
    }

    var isEmpty: Bool { nearest.isEmpty && earliest.isEmpty && vip.isEmpty }
    var isClientAgenda: Bool { mode == "client-agenda" }
}

struct AlternativesRequest: Encodable {
    let officeId: String
    let categoryCode: String?
    let typeCode: String?
    let limit: Int
    var clientAgenda: Bool = true
}

struct AlternativesResponse: Decodable {
    var offices: [GatewayOffice]
    var indexReady: Bool
    var mode: String
    var candidates: [GatewayCandidate]

    enum CodingKeys: String, CodingKey { case offices, indexReady, mode, candidates }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        offices = c.lenient(.offices, [])
        indexReady = c.lenient(.indexReady, false)
        mode = c.lenient(.mode, "")
        candidates = c.lenient(.candidates, [])
    }

    var isClientAgenda: Bool { mode == "client-agenda" }
}

// MARK: - /checklist

struct ChecklistItem: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var original: Bool
    var note: String
    var party: String

    enum CodingKeys: String, CodingKey { case id, name, original, note, party }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.lenient(.name, "")
        id = c.lenient(.id, "")
        if id.isEmpty { id = name }
        original = c.lenient(.original, false)
        note = c.lenient(.note, "")
        party = c.lenient(.party, "")
    }
}

struct ChecklistReminder: Codable, Hashable {
    var text: String
    var hoursBefore: Int

    enum CodingKeys: String, CodingKey { case text, hoursBefore }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = c.lenient(.text, "")
        hoursBefore = c.lenient(.hoursBefore, 0)
    }
}

struct ChecklistResponse: Decodable {
    var typeDesc: String
    var items: [ChecklistItem]
    var tips: [String]
    var documentsAreGeneric: Bool
    var disclaimer: String
    var reminder: ChecklistReminder?

    enum CodingKeys: String, CodingKey { case typeDesc, items, tips, documentsAreGeneric, disclaimer, reminder }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        typeDesc = c.lenient(.typeDesc, "")
        items = c.lenient(.items, [])
        tips = c.lenient(.tips, [])
        documentsAreGeneric = c.lenient(.documentsAreGeneric, false)
        disclaimer = c.lenient(.disclaimer, "")
        reminder = c.lenient(.reminder, nil as ChecklistReminder?)
    }
}

// MARK: - /share

struct ShareRequest: Encodable {
    let serviceId: String
    let lang: String
    let audience: String
    let officeName: String
    let officeAddress: String?
    /// dd/MM/yyyy
    let date: String
    let time: String
    let ticketNo: String
}

struct ShareResponse: Decodable {
    var text: String

    enum CodingKeys: String, CodingKey { case text }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = c.lenient(.text, "")
    }
}
