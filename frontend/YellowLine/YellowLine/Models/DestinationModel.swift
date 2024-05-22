//
//  DestinationModel.swift
//  YellowLine
//
//  Created by 정성희 on 4/11/24.
//

import Foundation

// 목적지 리스트 모델

struct DestinationModel: Codable {
    let searchPoiInfo: SearchPoiInfo
}

struct SearchPoiInfo: Codable {
    let pois: Pois
}

struct Pois: Codable {
    let poi: [PoiResult]
}

struct PoiResult: Codable {
    let name: String
    let frontLat : String
    let frontLon : String
    let newAddressList: NewAddress
}

struct NewAddress: Codable {
    let newAddress: [LocationInfo]
}

struct LocationInfo: Codable {
    let centerLat: String
    let centerLon: String
}
