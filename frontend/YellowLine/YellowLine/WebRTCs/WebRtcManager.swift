//
//  WebRtcManager.swift
//  YellowLine
//
//  Created by 이종범 on 4/16/24.
//

import Foundation
import UIKit
import WebRTC

class WebRtcManager: NSObject{
    var remoteViewTrack: RTCVideoTrack?
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    func p() {
        
    }
    
}

/**
 
 https://velog.io/@mquat/django-webRTC-websocket-django-channel-1
 
 */
