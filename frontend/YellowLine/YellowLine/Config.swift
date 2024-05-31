//
//  Config.swift
//  YellowLine
//
//  Created by 이종범 on 4/17/24.
//

import Foundation
import CoreML


fileprivate let _login = "http://43.202.136.75/user/login/"
fileprivate let _local = "ws://43.202.136.75:8001/yl/ws/sock/"
fileprivate let _signaling = "ws://43.202.136.75:8001/yl/ws/sock/"

fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",]
fileprivate let _mlModel = try! ylyolov8s(configuration: MLModelConfiguration()).model
// ai 모델
fileprivate let _midasModel = try! MiDaS()
struct Config {
    let webRTCServers: [String]
    let login : String
    let signaling : String
    let local : String
    let mlModel: MLModel
    let midasModel: MiDaS
    static let `urls` = Config(webRTCServers: defaultIceServers, login: _login, signaling: _signaling, local: _local, mlModel: _mlModel, midasModel: _midasModel)
}
