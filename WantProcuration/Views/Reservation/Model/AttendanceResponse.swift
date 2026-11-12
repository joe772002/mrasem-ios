//
//  AttendanceResponse.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 28/10/2025.
//


import Foundation

struct AttendanceResponse: Codable {
    let actualTimeToAttend: String?
    let attendedNo: Int?
    let statusCode: String
    let statusDesc: String
    let ticketNo: String?
}
