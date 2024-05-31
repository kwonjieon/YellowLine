//
//  RecentPathModel.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import Foundation

struct RecentPathModel: Codable {
    let user_history: [HistoryData]
}

struct HistoryData: Codable {
    let historyNum: Int
    let use_id: String
    let arrival: String
    let time: String
}
