//
//  NavigationDataModel.swift
//  YellowLine
//
//  Created by 정성희 on 4/9/24.
//

import Foundation

// 네비게이션 도보 주행 정보 모델

struct NavigationDataModel: Codable {
    let features: [FeaturesResult]
}
struct FeaturesResult: Codable {
    let properties: Properties
}
struct Properties: Codable {
    let description: String?
}
