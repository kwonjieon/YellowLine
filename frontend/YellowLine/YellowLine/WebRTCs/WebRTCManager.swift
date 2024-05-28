//
//  WebRtcManager.swift
//  YellowLine
//
//  Created by 이종범 on 4/16/24.
//

//import Foundation
import UIKit
import WebRTC
import Starscream

class WebRTCManager {
    var userName: String?
    var webRTCClient: WebRTCClient!
    var socket: WebSocket!
    var tryToConnectWebSocket: Timer!
    let ipAddress: String = "ws://0.tcp.jp.ngrok.io:16108/yl/ws/sock/"
    var cameraSession: CameraSession?
    var isSocketConnected = false
    var isParent = false
    
    
    init(_ view: UIImageView, _ midasView: UIImageView , _ userName: String) {
        self.userName = userName
        cameraSession = CameraSession(view: view, view2: midasView)
        cameraSession?.delegate = self
        webRTCClient = WebRTCClient()
        webRTCClient.delegate = self
        if cameraSession?.checkCameraAuthor() == true{
            cameraSession?.startVideo()
            webRTCClient.setupDevice()
            let request = URLRequest(url: URL(string: ipAddress + "\(self.userName!)/")!)
            socket = WebSocket(request: request)
            socket.delegate = self
            //websocket 연결 설정
            if !isParent {
//                DispatchQueue.global(qos: .background).async {
                    self.tryToConnectWebSocket = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { (timer) in
                        if self.webRTCClient.isConnected || self.isSocketConnected {
                            print("socket connected!")
                            return
                        }
                        print("Request socket connect")
                        self.socket.connect()
                    })
//                }
            }
        }
    }
    
    //MARK: UI setting
    func setupUI() {
        if isParent {
            
        } else {
            
        }
    }
    
    //MARK: UI Event mapping
    func callButtonTapped() {
        if !webRTCClient.isConnected {
            print("WebRTCManager 63: not connected")
            webRTCClient.connect(onSuccess: { (offerSDP: RTCSessionDescription) in
                self.sendSDP(sessionDescription: offerSDP)
            })
        }
    }
    
    func exitButtonTapped() {
        if webRTCClient.isConnected {
            webRTCClient.disconnect()
        }
    }
}

//MARK: - private WebRTC Signaling, RTCIceCandidate

extension WebRTCManager {
    private func sendSDP(sessionDescription: RTCSessionDescription) {
        var type = ""
        if sessionDescription.type == .offer {
            type = "offer"
        }else if sessionDescription.type == .answer {
            type = "answer"
        }
        
        let sdp = SDP.init(sdp: sessionDescription.sdp)
        let signalingMessage = SignalingMessage.init(type: type, sessionDescription: sdp, candidate: nil)
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            if self.isSocketConnected {
                self.socket.write(string: message)
            }
        }catch{
            print(error)
        }
    }
    
    private func sendCandidate(iceCandidate: RTCIceCandidate){
        let candidate = Candidate.init(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        let signalingMessage = SignalingMessage.init(type: "candidate", sessionDescription: nil, candidate: candidate)
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            if self.isSocketConnected {
                self.socket.write(string: message)
            }
        }catch{
            print(error)
        }
    }
}

//MARK: - WebSocket Delegate
extension WebRTCManager: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        print("WebSocketDelegate didReceive!")
        switch event {
        case .connected(let headers):
            self.isSocketConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            //아직 구현이 안됨.
            self.isSocketConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            do{
                let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: string.data(using: .utf8)!)
                
                if signalingMessage.type == "offer" {
                    webRTCClient.receiveOffer(srcOffer: RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!), onSuccess: {(answerSDP: RTCSessionDescription) in
                        self.sendSDP(sessionDescription: answerSDP)
                    })
                }else if signalingMessage.type == "answer" {
                    webRTCClient.receiveAnswer(descSdp: RTCSessionDescription(type: .answer, sdp: (signalingMessage.sessionDescription?.sdp)!))
                }else if signalingMessage.type == "candidate" {
                    let candidate = signalingMessage.candidate!
                    webRTCClient.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
                }
            }catch{
                print(error)
            }
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            self.isSocketConnected = false
        case .error(let error):
            self.isSocketConnected = false
//            handleError(error)
            print(error)
        case .peerClosed:
               break
        }
    }
}


//MARK: - WebRTCClient Delegate
extension WebRTCManager: WebRTCClientDelegate {
    func didOpenDataChanel() {
        print("did open data channel")
    }
    
    func didGenerateCandidate(iceCandidate: RTCIceCandidate) {
        self.sendCandidate(iceCandidate: iceCandidate)
    }
    
    func didConnectWebRTC() {
        //peer to peer 연결이 완료되면 socket연결은 필요없음.
        self.socket.disconnect()
    }
    
    func didDisConnectedWebRTC() {}
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        var state = ""
        
        switch iceConnectionState {
        case .checking:
            state = "checking..."
        case .closed:
            state = "closed"
        case .completed:
            state = "completed"
        case .connected:
            state = "connected"
        case .count:
            state = "count..."
        case .disconnected:
            state = "disconnected"
        case .failed:
            state = "failed"
        case .new:
            state = "new..."
        default:
            state = "something wrong default value."
        }
        print("ice candidation state changed: \(state)")
    }
    
    func didReceiveData(data: Data) {
        // data channel 을 연결했을 때 여기에 데이터가 옴. 추가기능임.
    }
    
    func didReceiveMessage(message: String) {
        // 위와 마찬가지 data channel용.
    }
}

extension WebRTCManager: CameraSessionDelegate {
    //didSampleOutput은 단순히 CameraSession + WebRTC동시 적용을 위한 테스트 카메라입니다. 삭제 필수!!!
    func didSampleOutput(_ ciImage: CIImage) {
//        DispatchQueue.main.async {
//            self._view?.image = UIImage(ciImage: ciImage)
//        }
    }
    
    // 확인해보니 WebRTC + CameraSession이 문제가 아니었음.
    // socket request가 문제로 보임. 모든 테스트 완료 후 문제 없으면 삭제하기.
    func didWebRTCOutput(_ sampleBuffer: CMSampleBuffer) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let rtcpixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let timeStampNs: Int64 = Int64(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000000000)
            let videoFrame = RTCVideoFrame(buffer: rtcpixelBuffer, rotation: RTCVideoRotation._0, timeStampNs: timeStampNs)
            
            self.webRTCClient?.didCaptureLocalFrame(videoFrame)
        }
    }
    
    
}
/**
 
 https://velog.io/@mquat/django-webRTC-websocket-django-channel-1
 
 */