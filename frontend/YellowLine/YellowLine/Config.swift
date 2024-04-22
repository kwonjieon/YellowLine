//
//  Config.swift
//  YellowLine
//
//  Created by 이종범 on 4/17/24.
//

import Foundation

//fileprivate let defaultSignalingServerUrl = URL(string: "ws://localhost:8001/yl/ws/sock/")

fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",]

struct Config {
    let webRTCServers: [String]
    
    static let `default` = Config(webRTCServers: defaultIceServers)
}
