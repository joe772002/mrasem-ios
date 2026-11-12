//
//  OfficeModel.swift
//  WantProcuration
//
//  Created by Fatma Informatique on 26/10/2025.
//

import Foundation
import SwiftUI
internal import CoreLocation

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? JSONDecoder().decode(Welcome.self, from: jsonData)



// MARK: - Welcome
struct OfficeResponse: Codable {
    let orgUnitStatusRes: OrgUnitStatusRes
}

// MARK: - OrgUnitStatusRes
struct OrgUnitStatusRes: Codable {
    let orgUnitStatusData: [OfficeModel]
    let responseDesc, responseStatus: String
}

// Custom decoding lives in an extension so the memberwise init (used by previews) is kept.
extension OrgUnitStatusRes {
    /// One bad office (missing / unexpected field) is skipped instead of failing the whole list.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orgUnitStatusData = try container.decodeLossyArray(OfficeModel.self, forKey: .orgUnitStatusData)
        responseDesc = try container.decodeIfPresent(String.self, forKey: .responseDesc) ?? ""
        responseStatus = try container.decodeIfPresent(String.self, forKey: .responseStatus) ?? ""
    }
}

// MARK: - OfficeModel
struct OfficeModel: Codable ,Identifiable{
    let id = UUID()
    let activeFlag: Int
    let QMeEnable: Int?
    let address: String
    let cnt, empNum: Int
    let fromTime: String
    let govDesc: String
    let isopened: Int
    /// Some offices come from the API without coordinates.
    let latitude, longtiude: String?
    let notServicedAm, notServicedPm, notServicedYet: Int
    let orgDesc: String
    let orgType: Int
    let orgTypeDesc: String
    let orgUnitID, orgUnitName, pluscodes, prcCntPerDay: String
    let queuingFlag, ticketEnabled: String
    let toTime: String
    let windowsNo: WindowsNo
   
    var distance : Double = 205
    
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude.flatMap { Double($0) } ?? 0,
                               longitude: longtiude.flatMap { Double($0) } ?? 0)
    }

    /// False when the API sent no (or unreadable / zero) coordinates. Such offices are excluded
    /// from "nearest" and from the map, but still appear in "all" and in search.
    var hasCoordinates: Bool {
        guard let lat = latitude.flatMap({ Double($0) }),
              let lon = longtiude.flatMap({ Double($0) }) else { return false }
        return lat != 0 && lon != 0
    }

    var isSpecial: Bool {
         orgType ==  1
      }
    
    var officeColor: Color {
        isSpecial ? .theme.gold : .theme.themeBlue.opacity(0.7)
    }
    enum CodingKeys: String, CodingKey {
        case activeFlag, address, cnt, empNum, fromTime, govDesc, isopened, latitude, longtiude, notServicedAm, notServicedPm, notServicedYet, orgDesc, orgType, orgTypeDesc,QMeEnable
        case orgUnitID = "orgUnitId"
        case orgUnitName, pluscodes, prcCntPerDay, queuingFlag, ticketEnabled, toTime, windowsNo
    }
}


enum WindowsNo: String, Codable {
    case null = "null"
}
