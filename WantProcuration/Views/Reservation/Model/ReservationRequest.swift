import Foundation
import SwiftUI
import Combine

class ReservationRequest: ObservableObject, Codable {
    @Published var customerIdType: String = ""
    @Published var customerId: String = ""
    @Published var orgUnitId: String = ""
    @Published var transactionTypeCategory: TransactionCategory?
    @Published var transactionType: TransactionType?
    @Published var reservationSlot: String = ""
    @Published var period: Int?
    @Published var mobileSerialNum: String = ""
    @Published var requestQueVIPId: String = ""
    @Published var mobileNum: String?
    @Published var reservationDay: ReservationDate?
    @Published var reservationPeriod: ReservePeriod?
    @Published var reservationTime: ReservationTime?
    
    private enum CodingKeys: String, CodingKey {
        case customerIdType
        case customerId
        case orgUnitId
        case transactionTypeCategory
        case transactionTypeCode
        case reservationSlot
        case period
        case mobileSerialNum
        case requestQueVIPId
        case mobileNum
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.customerIdType = try container.decodeIfPresent(String.self, forKey: .customerIdType) ?? "1"
        self.customerId = try container.decodeIfPresent(String.self, forKey: .customerId) ?? ""
        self.orgUnitId = try container.decodeIfPresent(String.self, forKey: .orgUnitId) ?? ""
        self.reservationSlot = try container.decodeIfPresent(String.self, forKey: .reservationSlot) ?? ""
        self.period = try container.decodeIfPresent(Int.self, forKey: .period)
        self.mobileSerialNum = try container.decodeIfPresent(String.self, forKey: .mobileSerialNum) ?? DeviceIdentity.id
        self.requestQueVIPId = try container.decodeIfPresent(String.self, forKey: .requestQueVIPId) ?? ""
        self.mobileNum = try container.decodeIfPresent(String.self, forKey: .mobileNum)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(customerIdType, forKey: .customerIdType)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(orgUnitId, forKey: .orgUnitId)
        
        // Encode category code
        if let categoryCode = transactionTypeCategory?.code {
            try container.encode(categoryCode, forKey: .transactionTypeCategory)
        }
        
        // Encode transaction type code
        if let typeCode = transactionType?.code {
            try container.encode(typeCode, forKey: .transactionTypeCode)
        }
        
        try container.encode(reservationSlot, forKey: .reservationSlot)
        try container.encode(period ?? 0, forKey: .period)
        try container.encode(mobileSerialNum, forKey: .mobileSerialNum)
        try container.encodeIfPresent(requestQueVIPId.isEmpty ? nil : requestQueVIPId, forKey: .requestQueVIPId)
        try container.encodeIfPresent(mobileNum, forKey: .mobileNum)
    }

    init() {
        self.customerIdType = "1"
        self.mobileSerialNum = DeviceIdentity.id
    }
    
    func updateField(id: String, value: Any) {
        switch id {
        case "customerId":
            customerId = value as? String ?? ""
        case "orgUnitId":
            orgUnitId = value as? String ?? ""
        case "transactionTypeCategory":
            transactionTypeCategory = value as? TransactionCategory ?? TransactionCategory()
        case "transactionTypeCode":
            transactionType = value as? TransactionType ?? TransactionType()
        case "reservationDay":
            reservationDay = value as? ReservationDate
        case "reservationPeriod":
            reservationPeriod = value as? ReservePeriod
        case "reservationTime":
            reservationTime = value as? ReservationTime
        default:
            break
        }
    }
    
    // MARK: - Prepare for API Submission
    
    /// Prepares the reservation request for VIP users (vipFlag = "1" or "4")
    /// reservationSlot format: "04-11-2025 09:30 AM"
    /// period should be 0
    func prepareForVIPSubmission() {
        guard let date = reservationDay?.dateReserved,
              let time = reservationTime?.reserveTime else {
            return
        }
        
        // Format: "04-11-2025 09:30 AM"
        // Convert date from "2025-11-04" to "04-11-2025"
        let formattedDate = formatDateForVIP(date)
        reservationSlot = "\(formattedDate) \(time)"
        period = 0
        
        Logger.info("VIP Reservation prepared - Slot: \(reservationSlot)")
    }
    
    /// Prepares the reservation request for regular users
    /// reservationSlot format: "20-11-2025 00:00"
    /// period should be the selected period code
    func prepareForRegularSubmission() {
        guard let date = reservationDay?.dateReserved,
              let periodObj = reservationPeriod,
              let periodCode = Int(periodObj.timePeriodCode) else {
            return
        }
        
        // Format: "20-11-2025 00:00"
        let formattedDate = formatDateForRegular(date)
        reservationSlot = "\(formattedDate) 00:00"
        period = periodCode
        
        Logger.info("Regular Reservation prepared - Slot: \(reservationSlot), Period: \(periodCode)")
    }
    
    // MARK: - Date Formatting Helpers
    
    private func formatDateForVIP(_ dateString: String) -> String {
        // Input: "2025-11-04"
        // Output: "04-11-2025"
        let components = dateString.split(separator: "-")
        if components.count == 3 {
            return "\(components[2])-\(components[1])-\(components[0])"
        }
        return dateString
    }
    
    private func formatDateForRegular(_ dateString: String) -> String {
        // Input: "2025-11-20"
        // Output: "20-11-2025"
        let components = dateString.split(separator: "-")
        if components.count == 3 {
            return "\(components[2])-\(components[1])-\(components[0])"
        }
        return dateString
    }
}
