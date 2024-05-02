//
//  SignalingMessage.swift
//  YellowLine
//
//  Created by 이종범 on 4/22/24.
//

import Foundation
//enum YLUserType : Codable{
//    case normal, handicap
//}

struct YLUser:Codable {
    let clientId: String
    let message: String
    let connDate: String
//    let userType : YLUserType
    
}

struct SignalingMessage: Codable {
    let type: String
    let sessionDescription: SDP?
    let candidate: Candidate?
}

struct SDP: Codable {
    let sdp : String
}

struct Candidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String
}
