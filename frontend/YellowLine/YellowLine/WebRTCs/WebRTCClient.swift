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
    
    var isProtector = false
    var isDataChannel = false
    
    static var factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    private let mediaConstraints = [kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    private var peerConnection : RTCPeerConnection?
    //local media stream
    //local Tracks
    private var localStream: RTCMediaStream?
    private var localVideoSource : RTCVideoSource?
    private var localVideoTrack : RTCVideoTrack!
    //remote Tracks
    private var remoteVideoTrack : RTCVideoTrack?
    private var videoCapturer : RTCVideoCapturer?
    private var remoteStream: RTCMediaStream?

    //Data channels
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    //data channel
    private var dataChannel: RTCDataChannel?
    //view
    private var localRenderView: RTCEAGLVideoView?
    private var localView: UIView!
    private var remoteRenderView: RTCEAGLVideoView?
    private var remoteView: UIView!
    
    //camera
    var cameraDevice: AVCaptureDevice?
    private var hasReceivedSDP = false
    
//    weak var device: AVCaptureDevice?
    public private(set) var isConnected: Bool = false
    
    override init() {
        super.init()
        print("WebRTC Client initialized.")

    }
    
    deinit {
        print("WebRTC Client Deinit")
//        self.peerConnection = nil
    }
    
    // MARK: Setting.
    func setupWithRole(isProtector role: Bool, _ view: UIView) {
        self.isProtector = role
        if isProtector {
            print("보호자 입니다")
            remoteView = view
            remoteRenderView = RTCEAGLVideoView(frame: remoteView.frame)
            remoteRenderView?.delegate = self
            remoteView.addSubview(remoteRenderView!)
        } else {
            print("피보호자 입니다")
            localView = view
            setupLocalTrack()
            startCapturerLocalVideo(cameraPosition: .back)
            //
            localRenderView = RTCEAGLVideoView()
            localRenderView!.delegate = self
            localView.addSubview(localRenderView!)
            localVideoTrack.add(localRenderView!)
        }
    }

    func localVideoView() -> UIView {
        return localView
    }
    
    func remoteVideoView() -> UIView {
        return remoteView
    }

    //MARK: - setup Connection( peerConnection, tracks, videoCapturer)
    func connect(onSuccess: @escaping (RTCSessionDescription) -> Void){
        self.peerConnection = setupPeerConnection()
        self.peerConnection?.delegate = self
        remoteVideoTrack = peerConnection!.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        self.dataChannel = self.setupDataChannel()
        self.dataChannel?.delegate = self

        makeOffer(onSuccess: onSuccess)
    }
    
    
    private func setupPeerConnection() -> RTCPeerConnection? {
        let constraints = RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        let config = generateConfig()
        let pc = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: self)
        
        return pc
    }
    
    
    // localframe 설정 (내 비디오트랙을 파이프라인에 보내기 위해 사용함.)
    func didCaptureLocalFrame(_ videoFrame: RTCVideoFrame) {
        guard let videoSource = self.localVideoSource,
            let videoCapturer = videoCapturer else { return }
        if !isProtector {
            videoSource.capturer(videoCapturer, didCapture: videoFrame)
        }
    }
    
    private func setupDataChannel() -> RTCDataChannel{
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.channelId = 0
        
        let _dataChannel = self.peerConnection?.dataChannel(forLabel: "dataChannel", configuration: dataChannelConfig)
        return _dataChannel!
    }
    
    private func setupLocalTrack() {
        debugPrint("call setupLocalTrack")
        let videoSource = WebRTCClient.factory.videoSource()
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.localStream = WebRTCClient.factory.mediaStream(withStreamId: "stream0")
        self.localVideoSource = videoSource
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        self.localVideoTrack = videoTrack
    }
    
    // MARK: 카메라 세팅
    private func startCapturerLocalVideo(cameraPosition: AVCaptureDevice.Position/*, videoFormat: [AVCaptureDevice.Format?]*/) {
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            var targetFormat : AVCaptureDevice.Format?
            var targetDevice: AVCaptureDevice?
            // find target device
            let devicies = RTCCameraVideoCapturer.captureDevices()
            devicies.forEach { (device) in
                if device.position ==  cameraPosition{
                    targetDevice = device
                }
            }
            
            let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice!)
            formats.forEach { (format) in
                for _ in format.videoSupportedFrameRateRanges {
                    let description = format.formatDescription as CMFormatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    if dimensions.width ==  640 && dimensions.height == 480 {
                        targetFormat = format
                    } else if dimensions.width == 1280 {
                        targetFormat = format
                    }
                }
            }
            DispatchQueue.global(qos: .userInitiated).async {
                capturer.startCapture(with: targetDevice!, format: targetFormat!, fps: 30)
            }
        }
    }
    func stopCapture() {
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            DispatchQueue.global(qos: .userInitiated).async {
                capturer.stopCapture()
            }
        }
    }

    

}

extension WebRTCClient {
    private func generateConfig() -> RTCConfiguration {
        let config = RTCConfiguration()
        //7200초 = 12분유지
        let wcert = RTCCertificate.generate(withParams: ["expires": NSNumber(value: 100000),
                                                         "name": "RSASSA-PKCS1-v1_5"])
        config.iceServers = [RTCIceServer(urlStrings: Config.urls.webRTCServers), RTCIceServer(urlStrings: ["turn:43.202.136.75:3478"], username: "mysteria", credential: "mysteria")]
        
        config.iceTransportPolicy = .all
//        config.rtcpMuxPolicy = .negotiate
        config.sdpSemantics = RTCSdpSemantics.unifiedPlan
        config.certificate = wcert
        
        return config
    }
    
    private func createDataChannel() -> RTCDataChannel?{
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection!.dataChannel(forLabel: "dataChannel", configuration: config) else {
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
        print("makeOffer 실행")
        self.peerConnection!.offer(for: RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil)) { (sdp, error) in
            if let error = error {
                print("error ! ")
                print(error)
                return
            }
            
            if let offerSDP = sdp {
                print("make offer and local sdp")
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
        print("makeOffer 종료")
    }
    
    private func makeAnswer(onSuccess : @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection?.answer(for: RTCMediaConstraints(mandatoryConstraints: mediaConstraints , optionalConstraints: nil)) { (sdp, error) in
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
        if self.peerConnection == nil {
            print("offer received, create peer connection.")
            self.peerConnection = setupPeerConnection()
            self.peerConnection!.delegate = self
            self.peerConnection!.add(localVideoTrack, streamIds: ["stream-0"])
            self.dataChannel = self.setupDataChannel()
            self.dataChannel?.delegate = self
        }
        
        debugPrint("set remote description.")
        self.peerConnection!.setRemoteDescription(srcOffer) { error in
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
        self.peerConnection!.setRemoteDescription(sdp) { (error) in
            if let error = error {
                print("failed to set remote offer sdp")
                print(error)
                return
            }
        }
    }
    
    func receiveCandidate(candidate: RTCIceCandidate) {
        self.peerConnection!.add(candidate) { error in
            if let error = error {
                print("receiveCandidate error ")
                debugPrint(error)
                return
            }
        }
    }
   
    //answer SDP 생성
    private func makeAnswerSdp(onSuccess : @escaping (RTCSessionDescription) -> Void) {
        print("= makeAnswerSDP")
        if self.peerConnection == nil {
            print("야 이거 answer 인데 nil이다 쩝...")
        }
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        self.peerConnection!.answer(for: constraints, completionHandler: { (rsdp, err) in
            if let error = err {
                print("makeAnswerSDP error")
                print(error)
                return
            }
            
            print("success to create local answer sdp.")
            if let answerSDP = rsdp {
                self.peerConnection!.setLocalDescription(answerSDP, completionHandler: { (err) in
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
        print("= END makeAnswerSDP")
    }
    


    //render video track data of the remote peer.
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack!.add(renderer)
    }
    
    // MARK: - CONNECTION EVENT
    func onConnected() {
        print("WebRTCClient onConnected")
        self.isConnected = true
        
        DispatchQueue.main.async {
            if self.isProtector {
                self.remoteRenderView!.isHidden = false
                self.delegate?.didConnectWebRTC()
            }

        }
    }

    func disconnect() {
        self.isConnected = false
        self.peerConnection?.close()
        self.peerConnection = nil
        print("WebRTCClient onDisConnected")
        DispatchQueue.main.async {
            self.remoteRenderView?.isHidden = true
            self.localDataChannel = nil
            self.hasReceivedSDP = false
            self.localVideoTrack = nil
            self.localVideoSource = nil
            self.remoteVideoTrack = nil
            self.cameraDevice = nil
            self.videoCapturer = nil
        }
        self.stopCapture()
    }
    
    func onDisConnected() {
        delegate?.didDisConnectedWebRTC()
    }
}

//MARK: -DataChannel Event
extension WebRTCClient {
    func sendMessage(message: String) {
        print("self.remoteDataChannel is null == \(self.remoteDataChannel == nil)")
        if let _dataChannel = self.remoteDataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: message.data(using: String.Encoding.utf8)!, isBinary: false)
                _dataChannel.sendData(buffer)

            }else {
                print("data channel is not ready state")
            }
        }else{
            print("no data channel")
        }
    }
    
    func sendData(data: Data){
        if let _dataChannel = self.remoteDataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: data, isBinary: true)
                _dataChannel.sendData(buffer)
            }
        }
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
            self.isConnected = false
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
    
    // MARK: remote
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("did add stream")
        if isProtector {
            self.remoteStream = stream
            if let track = stream.videoTracks.first {
                print("video track found!")
                remoteVideoTrack = track
                track.add(remoteRenderView!)
                track.isEnabled = true
            }
        }

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection newState = \(newState), self is connected = \(self.isConnected)")
        switch newState {
        case .connected, .completed:
            if !self.isConnected {
                self.onConnected()
            }
        default:
            break
//            if self.isConnected{
//                self.onDisConnected()
//            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didIceConnectionStateChanged(iceConnectionState: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
       //send message(video)
        print("generate Candidate")
        self.delegate?.didGenerateCandidate(iceCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.remoteDataChannel = dataChannel
        self.isDataChannel = true
        self.delegate?.didOpenDataChanel()
    }
    
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("data channel did change state")
        switch dataChannel.readyState {
        case .closed:
            print("closed")
        case .closing:
            print("closing")
        case .connecting:
            print("connecting")
        case .open:
            print("open")
        }
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        DispatchQueue.main.async {
            if buffer.isBinary {
                self.delegate?.didReceiveData(data: buffer.data)
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

        if isProtector {
            if videoView.isEqual(self.remoteRenderView!) {
                print("remote video size changed to: ", size)
                renderView = self.remoteRenderView
                parentView = self.remoteView
            }
        } else {
            if videoView.isEqual(localRenderView){
                print("local video size changed")
                renderView = localRenderView
                parentView = localView
            }
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
