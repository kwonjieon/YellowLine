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



protocol WebRTCManagerDelegate: AnyObject {
    func didRedOrGreenLight(_ text: String)
}

class WebRTCManager {
    var userName: String?
    var webRTCClient: WebRTCClient!
    var socket: WebSocket!
    var tryToConnectWebSocket: Timer!
    var cameraSession: CameraSession?
    var isSocketConnected = false
    var delegate: WebRTCManagerDelegate?
    
    // 내 화면 보여주는 uiview
    var localView: UIView?
    
    init(uiView : UIView,_ userName: String) {
        self.userName = userName
        self.localView = uiView
        cameraSession = CameraSession(view: uiView)
        cameraSession?.delegate = self
        webRTCClient = WebRTCClient()
        webRTCClient.delegate = self
        webRTCClient.cameraDevice = cameraSession!.cameraDevice
        webRTCClient.setupWithRole(isProtector: false, uiView)
        if cameraSession?.checkCameraAuthor() == true{
            //socket 연결요청
            let request = URLRequest(url: URL(string: Config.urls.signaling + "\(self.userName!)/")!)
            socket = WebSocket(request: request)
            socket.delegate = self
            self.tryToConnectWebSocket = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { (timer) in
                if self.webRTCClient.isConnected || self.isSocketConnected {
                    print("socket connected!")
                    return
                }
                print("Request socket connect")
                self.socket.connect()
            })
            // 카메라 실행
            cameraSession!.startVideo()
        }
    }
    
    func disconnect() {
        self.tryToConnectWebSocket.invalidate()
        
//        self.webRTCClient.stopCapture()
        self.webRTCClient.onDisConnected()
            if self.isSocketConnected {
                self.isSocketConnected = false
            }
        
        self.cameraSession = nil
        self.webRTCClient = nil

//            self.tryToConnectWebSocket = nil
////            self.cameraSession = nil
//            self.socket = nil



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
        print("==event: ",event)
        switch event {
        case .connected(let headers):
            self.isSocketConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            //아직 구현이 안됨.
            self.isSocketConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("WebSocket에서 자료를 받았습니다.")
            do{
                let message = try JSONDecoder().decode(Message.self, from: string.data(using: .utf8)!)
                let signalingMessage = message.message!

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
                print("didReceive Error 발생")
                print(error)
            }
//            print("Received text: \(string)")
        case .binary(let data):
            print("Websocket: Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("cancelled...")
            self.isSocketConnected = false
        case .error(let error):
            self.isSocketConnected = false
//            handleError(error)
            print("202 Error 발생.")
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
        print("Data received...! \(data)")
    }
    
    func didReceiveMessage(message: String) {
        // 위와 마찬가지 data channel용.
        print(message)
        
    }
}

// MARK: Render local view
extension WebRTCManager: CameraSessionDelegate {
    func didRedOrGreen(_ type: String) {
        delegate?.didRedOrGreenLight(type)
    }
    
    // video view에 표시하는 함수임.
    func didWebRTCOutput(_ sampleBuffer: CMSampleBuffer) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let rtcpixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let timeStampNs: Int64 = Int64(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000000000)
            // select rotation
            let videoFrame = RTCVideoFrame(buffer: rtcpixelBuffer, rotation: RTCVideoRotation._90, timeStampNs: timeStampNs)
            self.webRTCClient?.didCaptureLocalFrame(videoFrame)
        }
        
    }
    
    
    
}
/**
 
 https://velog.io/@mquat/django-webRTC-websocket-django-channel-1
 
 */

