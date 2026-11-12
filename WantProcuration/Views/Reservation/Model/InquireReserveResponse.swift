//
//  InquireReserveResponse.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 28/10/2025.
//


import Foundation

struct InquireReserveResponse: Codable {
    let inquireReserve: [InquireReserveItem]
    let statusCode: String
    let statusMessage: String
}

// Custom decoding lives in an extension so the memberwise init (used by previews) is kept.
extension InquireReserveResponse {
    /// A missing/null list means "no reservations"; an unreadable item is skipped and logged.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inquireReserve = try container.decodeLossyArray(InquireReserveItem.self, forKey: .inquireReserve)
        statusCode = try container.decodeIfPresent(String.self, forKey: .statusCode) ?? ""
        statusMessage = try container.decodeIfPresent(String.self, forKey: .statusMessage) ?? ""
    }
}

struct InquireReserveItem: Codable , Identifiable{
    var id = UUID()
    let orgId: String
    let orgName: String
    let orgVipFlag: String
    let periodId: String
    let queVipId: String
    let reservationDate: String
    let reserveTime: String
    let transactionCategoryId: String
    let transactionDesc: String
    let transactionTypeDesc: String
    let transactionTypeId: String
    
    var datePreview: String {
        let input = reservationDate.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.S"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let date = formatter.date(from: input) {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        } else {
            // fallback: if string doesn't match expected format
            return String(input.prefix(10))
        }
    }
    var timeRangePreview: String {
        let parts = reserveTime.split(separator: "-")
        if parts.count == 2 {
            let from = TimeDisplay.twelveHour(parts[0].trimmingCharacters(in: .whitespaces))
            let to = TimeDisplay.twelveHour(parts[1].trimmingCharacters(in: .whitespaces))
            return "from".localized() + " \(from) " + "to".localized() + " \(to)"
        } else {
            return TimeDisplay.twelveHour(reserveTime)
        }
    }
    enum CodingKeys: String, CodingKey {
        case orgId, orgName, orgVipFlag, periodId, queVipId, reservationDate, reserveTime, transactionCategoryId, transactionDesc, transactionTypeDesc, transactionTypeId
    }
}

// Lenient item decoding: the API may send a field as null, as a number, or not at all
// (e.g. reserveTime / queVipId for regular offices). Before this, such a reservation was
// skipped and the screen showed "0 reservations" even though the booking exists.
extension InquireReserveItem {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func text(_ key: CodingKeys) -> String {
            if let value = try? c.decodeIfPresent(String.self, forKey: key) { return value }
            if let value = try? c.decodeIfPresent(Int.self, forKey: key) { return String(value) }
            if let value = try? c.decodeIfPresent(Double.self, forKey: key) { return String(value) }
            return ""
        }
        id = UUID()
        orgId = text(.orgId)
        orgName = text(.orgName)
        orgVipFlag = text(.orgVipFlag)
        periodId = text(.periodId)
        queVipId = text(.queVipId)
        reservationDate = text(.reservationDate)
        reserveTime = text(.reserveTime)
        transactionCategoryId = text(.transactionCategoryId)
        transactionDesc = text(.transactionDesc)
        transactionTypeDesc = text(.transactionTypeDesc)
        transactionTypeId = text(.transactionTypeId)
    }
}
