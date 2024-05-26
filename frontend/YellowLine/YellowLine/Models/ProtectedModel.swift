//
//  ProtectedModel.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import Foundation
struct ProtectedModel: Codable {
    let results: [ResultData?]
}

struct ResultData: Codable {
    let id : String
    let name: String
    let phoneNum: String
    let latest_state : String
}
