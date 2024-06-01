//
//  ShowObjectDetectionVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/30/24.
//

import UIKit
import WebRTC
import AVKit
import Starscream


// 보호자가 보는 피보호자의 물체탐지 화면
class ShowObjectDetectionVC: UIViewController {
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var objectDetectionView: UIView! // remote view
    
//    private var protectedId = "YLUSER01" //보호자 아이디
    var protectedId : String?
    private var ipAddress: String = Config.urls.signaling
    
    var socket: WebSocket!
    var webRTCClient: WebRTCClient!
    var tryToConnectWebSocket: Timer!
    var isSocketConnected = false
    
    // 피보호자 정보
    var name: String?
    var id : String?
    
    @IBAction func clickBackBtn(_ sender: Any) {
        self.dismiss(animated: true)
        if webRTCClient.isConnected {
            webRTCClient.disconnect()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()   // ui setting
        let request = URLRequest(url: URL(string: ipAddress + "\(self.protectedId)/")!)
        socket = WebSocket(request: request)
        socket.delegate = self
        // socket 반복요청
        self.tryToConnectWebSocket = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { (timer) in
            if self.webRTCClient.isConnected || self.isSocketConnected {
                print("socket connected!")
                if !self.webRTCClient.isConnected {
                    self.webRTCClient.connect(onSuccess: { (offerSDP: RTCSessionDescription) in
                        self.sendSDP(sessionDescription: offerSDP)
                    })
                }
                return
            }
            print("Request socket connect")
            self.socket.connect()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webRTCClient = WebRTCClient()
        webRTCClient.delegate = self
        webRTCClient.setupWithRole(isProtector: true, objectDetectionView)
//        if isSocketConnected && !webRTCClient.isConnected {
//            webRTCClient.connect(onSuccess: { (offerSDP: RTCSessionDescription) in
//                self.sendSDP(sessionDescription: offerSDP)
//            })
//        }
    }
    
    private func setupUI() {
        setobjectDetectionView()
        setNavigationBar()
        setBackBtn()
        setNameLabel()
        let remoteVideoView = webRTCClient.remoteVideoView()
        remoteVideoView.center = objectDetectionView!.center
    }
    
    func setobjectDetectionView() {
        objectDetectionView.frame = CGRect(x: 0, y: 0, width: 394.09, height: 726)

        objectDetectionView.translatesAutoresizingMaskIntoConstraints = false
        objectDetectionView.widthAnchor.constraint(equalToConstant: 394.09).isActive = true
        objectDetectionView.heightAnchor.constraint(equalToConstant: 726).isActive = true
        objectDetectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        objectDetectionView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 126).isActive = true
    }
    
    func setNavigationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 126)
        navigationBar.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor

        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 126).isActive = true
    }
    
    func setBackBtn() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 33).isActive = true
        backBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 67).isActive = true
    }
    
    func setNameLabel() {
        nameLabel.text = name
        nameLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        nameLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        nameLabel.textAlignment = .center

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 76).isActive = true
    }

    //MARK: - private
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




// MARK: - WebRTC Delegate

extension ShowObjectDetectionVC : WebRTCClientDelegate{
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
//        print("Data received...! \(data)")

        do {
            let received = try JSONDecoder().decode(NaviProtectedPoint.self, from: data)
            print("received data\n : Lat(\(received.Lat)), Lng(\(received.Lng)), Destination(\(received.dest))")
        } catch {
            return
        }
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

//MARK: - Socket Delegate
extension ShowObjectDetectionVC: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            self.isSocketConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            self.isSocketConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
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
