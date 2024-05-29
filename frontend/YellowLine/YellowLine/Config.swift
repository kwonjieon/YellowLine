//
//  Config.swift
//  YellowLine
//
//  Created by 이종범 on 4/17/24.
//

import Foundation

fileprivate let defaultURLS = ["signaling" : "ws://43.202.136.75:8001/yl/ws/sock/",
                              "login" : "http://43.202.136.75/user/login/",
                               "localTest":"ws://43.202.136.75:8001/yl/ws/sock/"]

fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",]

struct Config {
    let webRTCServers: [String]
    let urls = URLBooks()
    struct URLBooks {
        var login : String { get {"http://43.202.136.75/user/login/"}}
        var signaling : String { get {"ws://43.202.136.75:8001/yl/ws/sock/"}}
        var local : String { get { "ws://43.202.136.75:8001/yl/ws/sock/" }}
    }
    static let `default` = Config(webRTCServers: defaultIceServers)
}
