//
//  ShowNavigationVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/30/24.
//

import UIKit
import TMapSDK
import CoreData
import WebRTC
import Starscream
import Alamofire
// 보호자가 보는 피보호자의 네비+물체감지 화면
class ShowNavigationVC: UIViewController, TMapViewDelegate, WebSocketDelegate, WebRTCClientDelegate {
    
    //WebRTC
    var socket: WebSocket!
    var webRTCClient: WebRTCClient!
    var tryToConnectWebSocket: Timer!
    var isSocketConnected = false
    
    // tmap 지도
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    var currentMarker:TMapMarker?
    @IBOutlet weak var mapContainerView: UIView!
    var isReadyLoadMap = false
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var navigationBar: UIView!
    
    @IBOutlet weak var standardLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var objectDetectionView: UIView!
    @IBOutlet weak var backBtn: UIButton!
    @IBAction func clickBackBtn(_ sender: Any) {
        self.dismiss(animated: true)
        if webRTCClient.isConnected {
            self.dismiss(animated: true)
        }
    }
    
    // 피보호자 아이디, 이름 정보
    var id : String?
    var name: String = ""
    var destination : String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //WebRT        
        webRTCClient = WebRTCClient()
        webRTCClient.delegate = self
        webRTCClient.setupWithRole(isProtector: true, objectDetectionView)
        let request = URLRequest(url: URL(string: Config.urls.signaling + "\(self.id!)/")!)
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
        
       getProtectedDestination()
        
        //Navi
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)
        mapContainerView.addSubview(self.mapView!)
        // 확대 레벨 기본 설정
        self.mapView?.setZoom(18)
        
        /*
        // 델리게이트 설정
        locationManger.delegate = self
        // 거리 정확도 설정
        locationManger.desiredAccuracy = kCLLocationAccuracyBest
        // 사용자에게 허용 받기 alert 띄우기
        locationManger.requestWhenInUseAuthorization()
        
        // 아이폰 설정에서의 위치 서비스가 켜진 상태라면
        if CLLocationManager.locationServicesEnabled() {
            print("위치 서비스 On 상태")
            locationManger.startUpdatingLocation() //위치 정보 받아오기 시작
            print(locationManger.location?.coordinate)
        } else {
            print("위치 서비스 Off 상태")
        }
        
         */

        setLabel()
        setObjectDetectionView()
        setBackBtn()
        setNameLabel()
        setNavigationBar()
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        isReadyLoadMap = true
        // 현재 위치로 지도 이동
        //self.mapView?.setCenter(CLLocationCoordinate2D(latitude: currentLat, longitude: currentLongi))
        
    }
    
    func getProtectedDestination() {
        print ("id : \(id)")
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let URL = "http://43.202.136.75/user/protected-info/"
        let tmpData : [String : String] = ["user_id" : id!]
        AF.upload(multipartFormData: { multipartFormData in for (key, val) in tmpData {
            multipartFormData.append(val.data(using: .utf8)!, withName: key)
        }
        },to: URL, method: .post, headers: header)
        .responseDecodable(of: DestinationResult.self){ response in
            DispatchQueue.main.async {
                switch response.result {
                case let .success(response):
                    print("불러오기 성공")
                    let result = response
                    // error가 없으면 통과
                    guard let destinationResult = result.recent_arrival else {
                        return
                    }
                    self.destinationLabel.text = destinationResult
                    print("id : \(destinationResult)")
                case let .failure(error):
                    print(error)
                    print("실패입니다.")
                    
                default:
                    print("something wrong...")
                    break
                }
            }
        } //Alamofire request end...
    }
    
    
    // 피보호자의 현재위치 마커 표기 업데이트
    func updateCurrentPositionMarker(currentLatitude: CLLocationDegrees, currentLongitude: CLLocationDegrees) {
        // 실시간 위치표기를 위한 기존 현재위치 마커 초기화
        if let existingMarker = currentMarker {
            existingMarker.map = nil
        }
        
        // 새로운 위치에 마커 생성 및 추가
        currentMarker = TMapMarker(position: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude))
        currentMarker?.map = mapView
        
        print("마커 업데이트")
    }
    
    func setMapContainerView() {

        mapContainerView.frame = CGRect(x: 0, y: 0, width: 393, height: 403)

        mapContainerView.translatesAutoresizingMaskIntoConstraints = false
        mapContainerView.widthAnchor.constraint(equalToConstant: 393).isActive = true
        mapContainerView.heightAnchor.constraint(equalToConstant: 403).isActive = true
        mapContainerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        mapContainerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 126).isActive = true
    }
    
    func setObjectDetectionView() {
        objectDetectionView.frame = CGRect(x: 0, y: 0, width: 393, height: 356)
        objectDetectionView.layer.backgroundColor = UIColor(red: 0.851, green: 0.851, blue: 0.851, alpha: 1).cgColor
        objectDetectionView.layer.cornerRadius = 20

        objectDetectionView.translatesAutoresizingMaskIntoConstraints = false
        objectDetectionView.widthAnchor.constraint(equalToConstant: 393).isActive = true
        objectDetectionView.heightAnchor.constraint(equalToConstant: 356).isActive = true
        objectDetectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        objectDetectionView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 496).isActive = true
    }
    
    func setBackBtn() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 33).isActive = true
        backBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80).isActive = true
    }
    
    func setNameLabel() {
        nameLabel.text = name
        nameLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        nameLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        nameLabel.textAlignment = .center

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 59).isActive = true
    }
    
    func setNavigationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 126)
        navigationBar.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor

        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 126).isActive = true
    }
    
    func setLabel() {
        //destinationLabel.text = destination
        destinationLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        destinationLabel.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 18)
        destinationLabel.textAlignment = .center
        destinationLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        standardLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        standardLabel.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 18)
        standardLabel.textAlignment = .center
        standardLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        
        
        // 목적지의 글자크기가 바뀌더라도 중앙정렬 유지
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 87).isActive = true
    }
}


//MARK: - private WebRTC Func

extension ShowNavigationVC {
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

// MARK: - WEBRTC Delegate
extension ShowNavigationVC{
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
    
    //webrtc 연결이 상호 종료된다면?
    func didDisConnectedWebRTC() {
        print("WebRTC연결이 종료되었습니다.")
        if webRTCClient.isConnected {
            DispatchQueue.global(qos: .userInteractive).async {
                self.tryToConnectWebSocket.invalidate()
                self.webRTCClient.disconnect()
//                self.dismiss(animated: true)
            }
        }
    }
    
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
//            print("received data\n : Lat(\(received.Lat)), Lng(\(received.Lng)), Destination(\(received.dest))")
            
            // 지도 로드가 된 후에 마커 표기 시작가능
            if  isReadyLoadMap == true {
                guard let latData = received.Lat else{return}
                guard let lngData = received.Lng else{return}
                
                // 지정된 위치로 마커 업데이트
                updateCurrentPositionMarker(currentLatitude: latData, currentLongitude: lngData)
                
                // 지정된 위치로 지도 중심 지정
                self.mapView?.setCenter(CLLocationCoordinate2D(latitude: latData, longitude: lngData))
                
                // 확대 레벨 설정
                self.mapView?.setZoom(18)
            }
        } catch {
            return
        }
    }
    
    func didReceiveMessage(message: String) {
        print(message)
        
    }
}

//MARK: - Socket Delegate
extension ShowNavigationVC {
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

