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
    let geometry: Geometries
}
struct Properties: Codable {
    let description: String?
    let nearPoiName: String?
}

enum Coordinates: Codable {
    case oneDimensional([Double])
    case twoDimensional([[Double]])
    
    init(from decoder: Decoder) throws {
        if let singleArray = try? [Double](from: decoder) {
            self = .oneDimensional(singleArray)
        } else if let nestedArray = try? [[Double]](from: decoder) {
            self = .twoDimensional(nestedArray)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid coordinates format"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        switch self {
        case .oneDimensional(let array):
            try array.encode(to: encoder)
        case .twoDimensional(let nestedArray):
            try nestedArray.encode(to: encoder)
        }
    }
}

struct Geometries: Codable {
    let coordinates: Coordinates
}
