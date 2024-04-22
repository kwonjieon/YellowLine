//
//  WebRTCClient.swift
//  YellowLine
//
//  Created by 이종범 on 4/17/24.
//

import Foundation
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, sendData data: Data)
    func didOpenDataChanel()
    func didGenerateCandidate(iceCandidate: RTCIceCandidate)
}

/**
 보호자 : VideoTrack (x)
 피보호자: VideoTrack (o)
 
 
 WebRTC를 하려면 먼저 절차가 필요하다.
 OFFER : 보호자 , ANSWER : 피보호자
 
 
 1. Peer A가 pc(peerConnection)을 이용해 OFFER를 만들고 B에게 전송한다.
 2. Peer B는 OFFER를 받고 SDP를 설정한 뒤, pc를 이용해 Answer를 만들고, A에게 전송한다.
 3. Peer A는 Answer를 받고, SDP를 설정한다.
 */

class WebRTCClient: NSObject{

    static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    private let mediaConstraints = [kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    private var localCandidates = [RTCIceCandidate]()
    private var peerConnection : RTCPeerConnection?
    //local media stream
    private var localStream: RTCMediaStream?
    private var remoteStream: RTCMediaStream?
    //local Tracks
    private var localVideoSource : RTCVideoSource?
    private var localVideoTrack : RTCVideoTrack?
    
    //remote Tracks
    private var remoteVideoTrack : RTCVideoTrack?
    private var videoCapturer : RTCVideoCapturer?
    
    weak var rtcDelegate : WebRTCClientDelegate?
    
    //Data channels
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    
    //View
    private var remoteRenderView: RTCEAGLVideoView?
    private var remoteView: UIView!
    
    //DI
//    private let remoteSinks: [RTCVideoRenderer]
    
    private var hasReceivedSDP = false
    weak var device: AVCaptureDevice?
    public private(set) var isConnected: Bool = false
    
    override init() {
        super.init()
    }
    
    //카메라 세팅하기
    func setupDevice(_ device: AVCaptureDevice) {
        self.device = device
        setup(device)
    }
    
    func setup(_ device: AVCaptureDevice) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement" : kRTCMediaConstraintsValueTrue])
        let config = generateConfig()
//        peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: self)
        peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)
        self.peerConnection?.delegate = self
        setupMediaSender()
        startCaptureLocalVideo(cameraDevice: device)
    }
    
    func setupRemoteViewFrame(frame: CGRect){
         remoteView.frame = frame
         remoteRenderView?.frame = remoteView.frame
     }
    
    //webrtc에 인식시킬 카메라 세팅
    private func startCaptureLocalVideo(cameraDevice: AVCaptureDevice?/*, videoFormat: [AVCaptureDevice.Format?]*/) {
        if let videoCapturer = self.videoCapturer as? RTCCameraVideoCapturer {
            var targetFormat : AVCaptureDevice.Format?
            print("==startCaptureLocalVideo setting...")
            let formats = RTCCameraVideoCapturer.supportedFormats(for: cameraDevice!)
            formats.forEach { (format) in
                for _ in format.videoSupportedFrameRateRanges {
                    let description = format.formatDescription as CMFormatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    print("Width: \(dimensions.width), Height: \(dimensions.height)")
                    if dimensions.width ==  640 && dimensions.height == (860) {
                        targetFormat = format
                    } else if dimensions.width == 640 {
                        targetFormat = format
                    }
                }
            }
            
            videoCapturer.startCapture(with: cameraDevice!, format: targetFormat!, fps: 10)
        }

    }
    
    //MARK: Connection
    //부모가 생성해야할 것. answer는 시각장애인이 해야한다.
    func connect(onSuccess: @escaping (RTCSessionDescription) -> Void){
        offer(onSuccess: onSuccess)
    }

    func disconnect() {
        hasReceivedSDP = false
        peerConnection?.close()
        
        peerConnection = nil
        localVideoTrack = nil
        localVideoSource = nil
        remoteVideoTrack = nil
        videoCapturer = nil
    }
}

extension WebRTCClient {
    private func generateConfig() -> RTCConfiguration {
        let config = RTCConfiguration()
        //7200초 = 12분유지
        let wcert = RTCCertificate.generate(withParams: ["expires": NSNumber(value: 7200),
                                                         "name": "RSASSA-PKCS1-v1_5"])
        config.iceServers = [RTCIceServer(urlStrings: Config.default.webRTCServers)]
        config.iceTransportPolicy = .all
        config.rtcpMuxPolicy = .negotiate
        
        config.sdpSemantics = RTCSdpSemantics.unifiedPlan
        config.certificate = wcert
        
        return config
    }
    
    private func setupMediaSender() {
        print("call setupMediaSender")
        guard let peerConnection = peerConnection else {
            print("setupMediaSender is error")
            return
        }
        
        //미디어 스트림 생성
        self.localStream = WebRTCClient.factory.mediaStream(withStreamId: "media")
        
        // 카메라 캡처 세팅
        // 로컬 비디오 트랙, 로컬 비디오 소스 세팅
        let videoSource = WebRTCClient.factory.videoSource()
        self.localVideoSource = videoSource
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "YUSERv0")
        self.localVideoTrack = videoTrack
        
       // 카메라 캡처 등록
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        
        
        // local view 생성

        
        // 미디어 스트림에 로컬 트랙 추가
        self.localStream?.addVideoTrack(self.localVideoTrack!)
        
        peerConnection.add(videoTrack, streamIds: ["YUSER"])
        
        self.remoteVideoTrack = peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }
    
    func createDataChannel() -> RTCDataChannel?{
        let config = RTCDataChannelConfiguration()
        
        guard let dataChannel = self.peerConnection?.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: cannot create datachannel.")
            return nil
        }
        return dataChannel
    }

}

//MARK: - SDP, RTCIceCandidate
//SDP 교환 단계
extension WebRTCClient {
    //offer를 생성하는 메서드
    func receiveOffer(onSuccess: @escaping (RTCSessionDescription) -> Void) {
        print("=offer called")
        
        if self.peerConnection == nil {
            print("offer received, create peer connection.")
            self.peerConnection = setup
        }
    }
    
    func makeOffer(onSuccess: @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection?.offer(for: RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil), completionHandler: { [weak self](sdp, error) in
            guard let self = self else {return}
            if let error = error {
                print("error ! ")
                print(error)
                return
            }
            
            guard let sdp = sdp else {
                if let error = error {
                    print(error)
                }
                return
            }
            
            self.setLocalSDP(sdp)
            onSuccess(sdp)
        })
    }
    
    //offer를 받고 answer SDP를 생성하는 메서드
    //피보호자가 영상을 보내야 하기 때문에 디바이스 세팅.
    func receiveAnswer(offerSdp sdp: RTCSessionDescription, onSuccess: @escaping (RTCSessionDescription) -> Void) {
        if self.peerConnection == nil {
            print("offer received, create peerConnection")
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement" : "true"])
            let config = generateConfig()
            self.peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: self)
            
            setupMediaSender()
            startCaptureLocalVideo(cameraDevice: device)
        }
        print("=receiveOffer")
        print("\tset remote sdp")
        self.peerConnection?.setRemoteDescription(sdp) { (error) in
            if let error = error {
                print("failed to set remote offer sdp")
                print(error)
                return
            }
            print("Success to set remote offer sdp")
            self.makeAnswerSdp(onSuccess: onSuccess)
        }
    }
   
    //answer SDP 생성
    private func makeAnswerSdp(onSuccess : @escaping (RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints, optionalConstraints: nil)
        self.peerConnection?.answer(for: constraints, completionHandler: { (rsdp, err) in
            if let error = err {
                print("makeAnswerSDP error")
                print(error)
                return
            }
            
            print("success to create local answer sdp")
            if let answerSDP = rsdp {
                self.peerConnection?.setLocalDescription(answerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("failed to set local description")
                        print(error)
                        return
                    }
                    
                    print("success to set local description")
                    onSuccess(answerSDP)
                })
            }
        })
    }
    
    private func setLocalSDP(_ sdp: RTCSessionDescription) {
        print("=setLocalSDP")
        guard let peerConnection = peerConnection else {
            print("setLocalSDP Error")
            return
        }
        
        peerConnection.setLocalDescription(sdp, completionHandler: { error in
            if let error = error {
                print(error)
            }
            
            //시각장애인에게 전송해야하는 코드를 추가해야함.
            //signaling서버 구현에 따라 시그널링 코드가 달라진다.
            
        })
    }
    
    //render video track data of the remote peer.
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(renderer)
    }
}

extension WebRTCClient {
    func receiveCandidate(candidate: RTCIceCandidate) {
        self.peerConnection!.add(candidate, completionHandler: { (error) in
            if let error = error {
                print("-ReceiveCandidate error")
                print(error)
            }
        })
    }
}

//MARK: -DataChannel Event
extension WebRTCClient {
    func sendMessage(message: Data?) {
//        if let _dataChannel = self.remoteDataChannel
    }
}

//MARK: - about delegate
// RTCPeerConnectionDelegate
extension WebRTCClient : RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        var state = ""
        switch stateChanged {
        case .stable:
            state = "stable"
        case .closed:
            state = "closed"
        case .haveLocalOffer:
            state="haveLocalOffer"
        case .haveLocalPrAnswer:
            state = "haveLocalPrAnswer"
        case .haveRemoteOffer:
            state = "haveRemoteOffer"
        case .haveRemotePrAnswer:
            state = "haveRemotePrAnswer"
        @unknown default:
            state = "unknown"
        }
        
        print("signaling state changed: \(state)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("did add stream")
        self.remoteStream = stream
        if let track = stream.videoTracks.first {
            print("video track found!")
            track.add(remoteRenderView!)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
       //send message(video)
        self.rtcDelegate?.didGenerateCandidate(iceCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.remoteDataChannel = dataChannel
        self.rtcDelegate?.didOpenDataChanel()
    }
    
    private func onConnect() {
        self.isConnected = true

    }
    
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("DataChannel did change state \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        DispatchQueue.main.async {
            if buffer.isBinary {
                debugPrint("DataChannel did receiveMessageWith: \(buffer.data)")
            } else {
                let msg = String(data: buffer.data, encoding: String.Encoding.utf8)
                
            }
        }
    }
    
    
}

/**
 https://github.com/stasel/WebRTC-iOS/tree/main/WebRTC-Demo-App/Sources/Services //webrtc ios
 https://developer.mozilla.org/ko/docs/Web/API/WebRTC_API/Signaling_and_video_calling // signaling server
 
 
 */
