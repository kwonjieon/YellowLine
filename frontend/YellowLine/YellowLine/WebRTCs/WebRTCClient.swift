//
//  WebRTCClient.swift
//  YellowLine
//
//  Created by 이종범 on 4/17/24.
//

import Foundation
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func didOpenDataChanel()
    func didGenerateCandidate(iceCandidate: RTCIceCandidate)
    func didConnectWebRTC()
    func didDisConnectedWebRTC()
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState)
    func didReceiveData(data: Data)
    func didReceiveMessage(message: String)
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
//    var isClient = false
    weak var delegate : WebRTCClientDelegate?
    
    static var factory: RTCPeerConnectionFactory = {
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
    private var localVideoTrack : RTCVideoTrack!
    //remote Tracks
    private var remoteVideoTrack : RTCVideoTrack?
    
    private var videoCapturer : RTCVideoCapturer?
    
    //Data channels
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    //View
    private var remoteRenderView: RTCEAGLVideoView?
    private var remoteView: UIView!
    
    //DI
//    private let remoteSinks: [RTCVideoRenderer]
    
    private var hasReceivedSDP = false
//    weak var device: AVCaptureDevice?
    public private(set) var isConnected: Bool = false
    
    override init() {
        super.init()
        print("WebRTC Client initialized.")
    }
    
    deinit {
        print("WebRTC Client Deinit")
        self.peerConnection = nil
    }
    
    //카메라 세팅하기
    func setupDevice(/*_ device: AVCaptureDevice*/) {
        print("setup device")
//        self.device = device
        setupLocalTrack()
        startCapturerLocalVideo(cameraPosition: .back)
    }
    
    func setupRemoteViewFrame(frame: CGRect){
         remoteView.frame = frame
         remoteRenderView?.frame = remoteView.frame
     }
    

    
    //MARK: - setup Connection( peerConnection, tracks, videoCapturer)
    func connect(onSuccess: @escaping (RTCSessionDescription) -> Void){
        self.peerConnection = setupPeerConnection()
        self.peerConnection?.delegate = self

        
        makeOffer(onSuccess: onSuccess)
    }
    
    // peerConnection
    private func setupPeerConnection() -> RTCPeerConnection? {
        let config = generateConfig()
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement" : kRTCMediaConstraintsValueTrue])
        let pc = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)
        
        return pc
    }
    
    private func setupMediaSender() {
        self.remoteVideoTrack = peerConnection!.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        
        // dataChannel생성은 지금 굳이 필요 없을듯 하다. 비디오 외 데이터 전송 시 이용하자.
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }
    
    func didCaptureLocalFrame(_ videoFrame: RTCVideoFrame) {
        guard let videoSource = self.localVideoSource,
            let videoCapturer = videoCapturer else { return }
        
        videoSource.capturer(videoCapturer, didCapture: videoFrame)
    }
    private func setupLocalTrack() {
        debugPrint("call setupLocalTrack")
//        guard let pc = self.peerConnection else {
//            print("setupMediaSender is error")
//            return
//        }
        
        //미디어 스트림 생성
        self.localStream = WebRTCClient.factory.mediaStream(withStreamId: "media")
        // 카메라 캡처 세팅
        // 로컬 비디오 트랙, 로컬 비디오 소스 세팅
        let videoSource = WebRTCClient.factory.videoSource()
        self.localVideoSource = videoSource
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "YLUSERv01")
        self.localVideoTrack = videoTrack
        // 카메라 캡처 등록
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        // local view 등록, 다른 곳에 정의해도 될 듯 하다.
        self.peerConnection?.add(self.localVideoTrack, streamIds: ["YLUSER01"])
//         미디어 스트림에 로컬 트랙 추가
//        self.localStream?.addVideoTrack(self.localVideoTrack!)
    }
    
    //webrtc에 인식시킬 카메라 세팅
    private func startCapturerLocalVideo(cameraPosition: AVCaptureDevice.Position/*, videoFormat: [AVCaptureDevice.Format?]*/) {
        if let videoCapturer = self.videoCapturer as? RTCCameraVideoCapturer {
            var targetDevice: AVCaptureDevice?
            // find target device
            let devicies = RTCCameraVideoCapturer.captureDevices()
            devicies.forEach { (device) in
                if device.position ==  cameraPosition{
                    targetDevice = device
                }
            }
            
            var targetFormat : AVCaptureDevice.Format?
            let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice!)
            print("==startCaptureLocalVideo setting...")
            formats.forEach { (format) in
                for _ in format.videoSupportedFrameRateRanges {
                    let description = format.formatDescription as CMFormatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    if dimensions.width ==  1280 && dimensions.height == 720 {
                        targetFormat = format
                    } else if dimensions.width == 1280 {
                        targetFormat = format
                    }
                }
            }
//            let formats = cameraDevice?.formats
//            videoCapturer.startCapture(with: cameraDevice! , format: targetFormat!, fps: 15)
        }
    }

    
    func disconnect() {
        self.isConnected = false
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
    
    private func createDataChannel() -> RTCDataChannel?{
        let config = RTCDataChannelConfiguration()
        
        guard let dataChannel = self.peerConnection?.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: cannot create datachannel.")
            return nil
        }
        return dataChannel
    }

}

//MARK: - make and receive SDP, RTCIceCandidate
//SDP 교환 단계
extension WebRTCClient {
    //offer를 생성하는 메서드
    private func makeOffer(onSuccess: @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection?.offer(for: RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil)) { (sdp, error) in
            if let error = error {
                print("error ! ")
                print(error)
                return
            }
            
            
            if let offerSDP = sdp {
                print("make offer and locak sdp")
                self.peerConnection!.setLocalDescription(offerSDP, completionHandler: { (err) in
                    if let error = err {
                        print(error)
                        return
                    }
                    print("success to set local offer sdp")
                    onSuccess(offerSDP)
                })
            }
        }
    }
    
    private func makeAnswer(onSuccess : @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection?.answer(for: RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil)) { (sdp, error) in
            if let error = error {
                print("error ! ")
                print(error)
                return
            }
            
            print("success to create local answer sdp")
            if let answerSDP = sdp {
                self.peerConnection!.setLocalDescription(answerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("failed to set local answer sdp")
                        print(error)
                        return
                    }
                    
                    print("success to set local answer sdp")
                    onSuccess(answerSDP)
                })
            }
        }
    }

    func receiveOffer(srcOffer: RTCSessionDescription, onSuccess: @escaping (RTCSessionDescription) -> Void) {
        print("=receive Offer called")
        
        if self.peerConnection == nil {
            print("offer received, create peer connection.")
            self.peerConnection = setupPeerConnection()
            self.peerConnection?.delegate = self
            
            setupLocalTrack()
        }
        
        debugPrint("set remote description.")
        self.peerConnection?.setRemoteDescription(srcOffer) { error in
            if let error = error {
                debugPrint("Oh, receiveOffer has been problem.")
                debugPrint(error)
                return
            }
            
            print("success set remote sdp")
            self.makeAnswerSdp(onSuccess: onSuccess)
        }
    }
    
    //offer를 받고 answer SDP를 생성하는 메서드
    //피보호자가 영상을 보내야 하기 때문에 디바이스 세팅.
    func receiveAnswer(descSdp sdp: RTCSessionDescription) {
        print("=receiveOffer")
        self.peerConnection?.setRemoteDescription(sdp) { (error) in
            if let error = error {
                print("failed to set remote offer sdp")
                print(error)
                return
            }
//            print("Success to set remote offer sdp")
//            self.makeAnswerSdp(onSuccess: onSuccess)
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
            
            print("success to create local answer sdp.")
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
    
    func receiveCandidate(candidate: RTCIceCandidate) {
        self.peerConnection!.add(candidate) { error in
            if let error = error {
                debugPrint(error)
                return
            }
        }
    }

    //render video track data of the remote peer.
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(renderer)
    }
    
    // MARK: - CONNECTION EVENT
    private func onConnected() {
        print("WebRTCClient onConnected")
        self.isConnected = true
        DispatchQueue.main.async {
            self.remoteRenderView?.isHidden = false
            self.delegate?.didConnectWebRTC()
        }
    }
    
    private func onDisConnected() {
        self.isConnected = false
        print("WebRTCClient onDisConnected")
        self.remoteRenderView?.isHidden = true
        self.peerConnection!.close()
        self.peerConnection = nil
        self.localDataChannel = nil
        self.delegate?.didDisConnectedWebRTC()
    }
    
}

//MARK: -DataChannel Event
extension WebRTCClient {
    func sendMessage(message: Data?) {
//        if let _dataChannel = self.remoteDataChannel
    }
}

//MARK: - RTCPeerConnectionDelegate
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
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected, .completed:
            if !self.isConnected {
                self.onConnected()
            }
        default:
            if self.isConnected{
                self.onDisConnected()
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didIceConnectionStateChanged(iceConnectionState: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
       //send message(video)
        self.delegate?.didGenerateCandidate(iceCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.remoteDataChannel = dataChannel
        self.delegate?.didOpenDataChanel()
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
                self.delegate?.didReceiveData(data: buffer.data)
//                debugPrint("DataChannel did receiveMessageWith: \(buffer.data)")
            } else {
                let msg = String(data: buffer.data, encoding: String.Encoding.utf8)
                self.delegate?.didReceiveMessage(message: msg!)
                
            }
        }
    }
}

//MARK: - RTCVideoView delegate
extension WebRTCClient: RTCVideoViewDelegate {
    func videoView(_ videoView: any RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        let isLandScape = size.width < size.height
        var renderView: RTCEAGLVideoView?
        var parentView: UIView?
        
        if videoView.isEqual(self.remoteRenderView!) {
            print("remote video size changed to: ", size)
            renderView = self.remoteRenderView
            parentView = self.remoteView
        }
        guard let _renderView = renderView, let _parentView = parentView else {
            print("webrtc 491 line : something wrong.")
            return
        }
        if(isLandScape){
            let ratio = size.width / size.height
            _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.height * ratio, height: _parentView.frame.height)
            _renderView.center.x = _parentView.frame.width/2
        }else{
            let ratio = size.height / size.width
            _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.width, height: _parentView.frame.width * ratio)
            _renderView.center.y = _parentView.frame.height/2
        }
    }
    
    
}


/**
 https://github.com/stasel/WebRTC-iOS/tree/main/WebRTC-Demo-App/Sources/Services //webrtc ios
 https://developer.mozilla.org/ko/docs/Web/API/WebRTC_API/Signaling_and_video_calling // signaling server
 
 
 */
