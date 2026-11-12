//
//  TransactionCategory.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import Foundation

struct TransactionCategory: Codable, Identifiable , Pickable {
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
    init(){}
}
struct TransactionType: Codable, Identifiable , Pickable {
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
    init(){}
}


struct ValidateIdentity: Codable  {
   
    var statusCode: String?
    var statusDesc: String?
    
}
