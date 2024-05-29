//
//  TempVideoViewController.swift
//  YellowLine
//
//  Created by 이종범 on 5/28/24.
//

import UIKit
import WebRTC
import AVKit
import Starscream



class TempViewController: UIViewController, WebSocketDelegate, WebRTCClientDelegate {
    private var protectedId = "YLUSER01"
    private var ipAddress: String = Config.default.signalingURL
    
    
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var remoteView: UIView!
    @IBOutlet var Connect: UIButton! // 비디오 요청 버튼
    
    var socket: WebSocket!
    var webRTCClient: WebRTCClient!
    var webRTCManager: WebRTCManager?
    var tryToConnectWebSocket: Timer!
    var isSocketConnected = false
    
    override func viewDidLoad() {
        webRTCClient = WebRTCClient()
        webRTCClient.delegate = self
        webRTCClient.setupWithRole(isProtector: true, remoteView)
        setupUI()   // ui setting
        let request = URLRequest(url: URL(string: ipAddress + "\(self.protectedId)/")!)
        socket = WebSocket(request: request)
        socket.delegate = self
        // socket 반복요청
        self.tryToConnectWebSocket = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (timer) in
            if self.webRTCClient.isConnected || self.isSocketConnected {
                print("socket connected!")
                return
            }
            print("Request socket connect")
            self.socket.connect()
        })
    }
    
    //MARK: UI setting
    func setupUI() {
        let remoteVideoView = webRTCClient.remoteVideoView()
        remoteVideoView.center = remoteView!.center
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if webRTCClient.isConnected {
            webRTCClient.disconnect()
        }
    }
    
    @IBAction func connectBtn(_ sender: Any) {
        if !isSocketConnected {
            self.socket.connect()
        }
        
        if isSocketConnected && !webRTCClient.isConnected {
            webRTCClient.connect(onSuccess: { (offerSDP: RTCSessionDescription) in
                self.sendSDP(sessionDescription: offerSDP)
            })
        }
    }
    
    @IBAction func sendTextBtn(_ sender: Any) {
        let testText = "connect 확인."
        webRTCClient.sendMessage(message: testText)
    }
    

    
}


extension UIImage {

    public var base64: String {
        return self.jpegData(compressionQuality: 1.0)!.base64EncodedString()
    }

    convenience init?(base64: String, withPrefix: Bool) {
        var finalData: Data?

        if withPrefix {
            guard let url = URL(string: base64) else { return nil }
            finalData = try? Data(contentsOf: url)
        } else {
            finalData = Data(base64Encoded: base64)
        }

        guard let data = finalData else { return nil }
        self.init(data: data)
    }

}






// MARK: - WebRTC Delegate
extension TempViewController{
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
//        let converted = UIImage(base64: message, withPrefix: false)
//        DispatchQueue.main.async {
//            self.imageView!.image = converted
//        }
        print(message)
        
    }
    
}

// MARK: - Socket Delegate
extension TempViewController {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
//        print("WebSocketDelegate didReceive!")
//        print("==event: ",event)
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
                let message = try JSONDecoder().decode(Message.self, from: string.data(using: .utf8)!)
                let signalingMessage = message.message!
                
                if signalingMessage.type != nil {
                    print("Signaling Message다, type : ",signalingMessage.type)
                }
                
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
                print("=ERROR didReceive Error 발생")
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


//MARK: - WEBRTC용 함수 모음
extension TempViewController {
    private func sendSDP(sessionDescription: RTCSessionDescription) {
        var type = ""
        if sessionDescription.type == .offer {
            type = "offer"
        }else if sessionDescription.type == .answer {
            print("sendSDP: sendSDP type answer...")
            type = "answer"
        }
        
        let sdp = SDP.init(sdp: sessionDescription.sdp)
        let signalingMessage = SignalingMessage.init(type: type, sessionDescription: sdp, candidate: nil)
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            if self.isSocketConnected {
                print("self.isSocketConnected 입니다! 지금부터 sendSDP를 실행합니다!")
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
                print("self.isSocketConnected 입니다! 지금부터 sendCandidate를 실행합니다!")
                self.socket.write(string: message)
            }
        }catch{
            print(error)
        }
    }
}
