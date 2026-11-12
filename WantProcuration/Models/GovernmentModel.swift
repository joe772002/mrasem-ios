//
//  GovernmentModel.swift
//  WantProcuration
//
//  Created by Fatma Informatique on 26/10/2025.
//

import Foundation



struct GovernmentModel: Codable {
    // Only `lookupData` is used. The other fields are optional so a missing one
    // can't fail the whole governorates list (same issue we had with offices and agenda).
    let type, responseStatus, responseStatusDesc, channelRequestID: String?
    let correlationID: String?
    let lookupData: [lookupData]
    let minutesOfValidity, originatingChannel: Int?
    let originatingUserIdentifier: String?
    let originatingUserType: Int?

    enum CodingKeys: String, CodingKey {
        case type, responseStatus, responseStatusDesc
       
        case correlationID = "correlationId"
     
        case channelRequestID = "channelRequestId"
        case lookupData, minutesOfValidity, originatingChannel, originatingUserIdentifier, originatingUserType
    }
}

/// The property `lookupData` hides the type `lookupData` inside the struct, so it gets another name here.
typealias LookupItem = lookupData

// One bad governorate is skipped instead of failing the list; a missing list = empty.
extension GovernmentModel {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        responseStatus = try container.decodeIfPresent(String.self, forKey: .responseStatus)
        responseStatusDesc = try container.decodeIfPresent(String.self, forKey: .responseStatusDesc)
        channelRequestID = try container.decodeIfPresent(String.self, forKey: .channelRequestID)
        correlationID = try container.decodeIfPresent(String.self, forKey: .correlationID)
        lookupData = try container.decodeLossyArray(LookupItem.self, forKey: .lookupData)
        minutesOfValidity = try container.decodeIfPresent(Int.self, forKey: .minutesOfValidity)
        originatingChannel = try container.decodeIfPresent(Int.self, forKey: .originatingChannel)
        originatingUserIdentifier = try container.decodeIfPresent(String.self, forKey: .originatingUserIdentifier)
        originatingUserType = try container.decodeIfPresent(Int.self, forKey: .originatingUserType)
    }
}

// MARK: - LookupDatum
struct lookupData: Codable {
    let code, desc: String
}
