//
//  WebSocketManager.swift
//  YellowLine
//
//  Created by 이종범 on 4/14/24.
//

import Foundation
import UIKit
import WebRTC



class WebSocketManager : WebRTCClientDelegate{

    private var webSocketTask: URLSessionWebSocketTask?
    private var rtcWebSocketTask: URLSessionWebSocketTask?
    
    var imageView: UIImageView?
    
    var webRtcClient = WebRTCClient()
    
    private let ipAddress: String = "ws://0.tcp.jp.ngrok.io:11599"
    
    init(view: UIImageView){
        self.imageView = view
        guard let _imgview = self.imageView else {return }
        self.connect()
    }
    
    //MARK: - RTC 부분
    func disconnectRtc() {
        rtcWebSocketTask?.cancel(with: .goingAway, reason: nil)
        webRtcClient.disconnect()
    }
    
    // 네비게이션을 시작하는 유저정보 전달하는 함수
    // RTC 웹 소켓도 같이 시작함.
    func connectRtc(_ clientId: String) {
        print("===sendInitialInfo(), start RTC Websocket.")
        let localAddressIp = "\(ipAddress)/yl/ws/sock/\(clientId)/"
        print(localAddressIp)
        guard let rtcUrl = URL(string: "\(ipAddress)/yl/ws/sock/\(clientId)/") else { return }
        rtcWebSocketTask = URLSession(configuration: .default).webSocketTask(with: rtcUrl)
        rtcWebSocketTask?.resume()
        self.rtcReceiveMessage()
        
//        print("====start sending initial info of th client.")
//        let date:Date = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        let dateString = dateFormatter.string(from: date)
//        //접속 유저정보를 담고 있는 codable 모델 생성
//        let _ylUser = YLUser(clientId: "YLUser01", message: "", connDate: dateString)
//        
//        do {
//            print("gogogo")
//            let ylUser = try String(data: JSONEncoder().encode(_ylUser), encoding: .utf8)!
//            rtcWebSocketTask?.send(.string(ylUser)) { error in
//                if let error = error {
//                    print("error...")
//                    debugPrint(error)
//                    return
//                }
//            }
//        } catch {
//            print(error)
//        }
//        print("===")
        
        webRtcClient.connect(onSuccess: {(offerSDP: RTCSessionDescription) -> Void in
            self.sendSDP(offerSDP)
        })
    }
    
    func sendSDP(_ sessionDescription: RTCSessionDescription) {
        var type = ""
        if sessionDescription.type == .offer{
            type = "offer"
        }else if sessionDescription.type == .answer {
            type = "answer"
        }
        
        let sdp = SDP.init(sdp: sessionDescription.sdp)
        let signalingMessage = SignalingMessage(type: type, sessionDescription: sdp, candidate: nil)
        do {
            let message = try String(data: JSONEncoder().encode(signalingMessage), encoding: .utf8)!
            
            if self.rtcWebSocketTask?.state == .running {
                self.rtcWebSocketTask?.send(.string(message)) { error in
                    if let error = error {
                        print("92: ERROR 발생!")
                        print(error)
                    }
                }
            }
        } catch {
            print("98: ERROR 발생!")
            print(error)
        }
        
    }

    func sendCandidate(iceCandidate: RTCIceCandidate) {
        let candidate = Candidate.init(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        let signalingMessage = SignalingMessage.init(type: "candidate", sessionDescription: nil, candidate: candidate)
        do {
            let message = try String(data: JSONEncoder().encode(signalingMessage), encoding: .utf8)!
            if self.rtcWebSocketTask?.state == .running {
                self.rtcWebSocketTask?.send(.string(message)) { error in
                    if let error = error {
                        print("112: ERROR 발생!")
                        print(error)
                    }
                }
            }
        } catch {
            print("118: ERROR 발생!")
            print(error)
        }
        
    }
    
    private func rtcReceiveMessage() {
        self.rtcWebSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                    // Answer SDP를 받았을 때 처리하는 코드를 추가한다.
                    do {
                        let _signalingMessage = try JSONDecoder().decode(Message.self, from: text.data(using: .utf8)!)
                        let signalingMessage = _signalingMessage.message!
                        
                        switch signalingMessage.type {
                        case "offer":
                            self?.webRtcClient.receiveOffer(srcOffer: RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!), onSuccess: {(answerSDP: RTCSessionDescription) -> Void in
                                self?.sendSDP(answerSDP)
                            })
                            print("receive and offer SDP Complete!")
                        case "answer":
                            self?.webRtcClient.receiveAnswer(descSdp: RTCSessionDescription(type: .answer, sdp: (signalingMessage.sessionDescription?.sdp)!))
                        case "candidate":
                            let candidate = signalingMessage.candidate!
                            self?.webRtcClient.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
                        default:
                            print("No types in here")
                        }
                    } catch {
                        print(error)
                    }
                case .data(let data):
                    print("Received data type")
                @unknown default:
                    fatalError()
                }
                
                // Continue receiving messages
                self?.receiveMessage()
            }
        }
        
    }

    

    
}
//MARK: - WebRTCClientDelegate extension
extension WebSocketManager {
    func didGenerateCandidate(iceCandidate: RTCIceCandidate) {
        self.sendCandidate(iceCandidate: iceCandidate)
    }
    func didOpenDataChanel() {
        
    }
}

//MARK: - 영상 보내는 부분
extension WebSocketManager {
    
    func connect() {
        //img 보내는 소켓서버 url
        guard let url = URL(string: "\(ipAddress)/yl/ws/") else {return}
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
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
