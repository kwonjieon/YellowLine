//
//  WebSocketManager.swift
//  YellowLine
//
//  Created by 이종범 on 4/14/24.
//

import Foundation
import UIKit

struct YLUser:Codable {
    let clientId: String
    let connDate: String
}

class WebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    var imageView: UIImageView?
    
    init(view: UIImageView){
        self.imageView = view
        guard let _imgview = self.imageView else {return }
    }
    
    func connect() {
        //img 보내는 소켓서버 url
        guard let url = URL(string: "ws://0.tcp.jp.ngrok.io:13229/yl/ws/sock/") else {return}
        //offer 보내는 소켓 서버 url
//        guard let offerUrl = URL(string: something) else {return}
        
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        
        webSocketTask?.resume()
        receiveMessage()
        self.sendInitialInfo()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    //네비게이션을 시작하는 유저정보 전달하는 함수
    func sendInitialInfo() {
        print("===sendInitialInfo()")
        let date:Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        //접속 유저정보를 담고 있는 codable 모델 생성
        let _ylUser = YLUser(clientId: "YLUser01", connDate: dateString)
        
        do {
            print("gogogo")
            let ylUser = try String(data: JSONEncoder().encode(_ylUser), encoding: .utf8)!
            webSocketTask?.send(.string(ylUser)) { error in
                if let error = error {
                    print("error...")
                    debugPrint(error)
                    return
                }
            }
        } catch {
            print(error)
        }
        print("===")
    }
    
    func send(image: Data) {
        webSocketTask?.send(.data(image)) { error in
            if let error = error {
                print("Error sending image: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                CameraSession.isUploaded = false
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                    // Answer SDP를 받았을 때 처리하는 코드를 추가한다.
                    
                case .data(let data):
                    let received = UIImage(data: data)
                    DispatchQueue.main.async {
                        self?.imageView?.image = received
                    }
                @unknown default:
                    fatalError()
                }
                
                // Continue receiving messages
                self?.receiveMessage()
            }
        }
    }
    
}

/**
 1. 스트리밍 동영상 데이터를 가져옵니다.
 2. 네트워크 정보(ip, port)를 가져오고 다른 WebRTC 클라이언트 (피어라고 함)와 교환하여 NAT 및 방화벽을 통해서도 연결을 사용 설정합니다.
 3. 신호 통신을 조정하여 오류를 보고하고 세션을 시작하거나 종료합니다.
 4. 해상도 및 코덱과 같은 미디어 및 클라이언트 기능에 관한 정보를 교환합니다.
 5. 스트리밍 오디오, 동영상 또는 데이터를 전달합니다.
 
 //SERVER
피보호자가 socket connect하면 서버에서 사용자의 id를 웹소켓 서버에 active유저로 저장해야 합니다.
피보호자가 server disconnect하면 서버에서 사용자 id를 웹소켓 서버에서 deactive유저로 저장해야 합니다
 
 */
