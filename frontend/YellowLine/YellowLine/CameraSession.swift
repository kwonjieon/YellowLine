//
//  Sessions.swift
//  YellowLine
//
//  Created by 이종범 on 4/8/24.
//

import Foundation
import AVFoundation
import UIKit
import Combine
//import Alamofire

class CameraSession: NSObject {
    var captureSession: AVCaptureSession
    let videoOutput: AVCaptureVideoDataOutput 
    let imgUrl: String!
    var queue: DispatchQueue?
    var _image: UIImage?
    var _imageView: UIImageView?
//    var subscriptions = Set<AnyCancellable>()
    
    var deviceFormat: AVCaptureDevice.Format?
    
//    var preferredOutputPixelFormat = FourCharCode("BGRA")
    var preferredOutputPixelFormat: FourCharCode = 0

    //networkmanager는 websocket을 사용하기 때문에 현재 사용안함. 나중에 추가로 서버와 통신할 때 간단한 통신작업만 추가할예정.
//    let _networkManager = NetworkManager(url : URL(string: "ws://0.tcp.jp.ngrok.io:15046/yl/ws/"))
    let socketManager: WebSocketManager?
    
    static var isUploaded = false
    
    let clientId = "YLUser01"
    
    init(queue: DispatchQueue, view: UIImageView?){
        //url도 websocket 주소로 바꿀계획.
        self.imgUrl = "https://145b-182-222-253-136.ngrok-free.app/yl/img"
        self.captureSession = .init()
        self.videoOutput = .init()
        self.queue = queue
        // 뷰를 빈으로 등록해(ex:@State 같은 어노테이션) 나중에 이와같은 코드를 없애버리자.
        self._imageView = view
        //run websocket
        self.socketManager = WebSocketManager(view: self._imageView!)

    }
    
    func checkCameraAuthor() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
                    self.setupCameraSession()
                }
            })
        default:
            break
        }
    }
    
    
    
    //MARK: -세팅:카메라 세션
    func setupCameraSession() {
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = .high
        
        // input setting
        let _device = setupInput(w: 320, h:240)
        
        //output setting
        setupOutput()
        
        //add input and output
        do {
            let cameraInput = try AVCaptureDeviceInput(device: _device!)
            if captureSession.canAddInput(cameraInput) && captureSession.canAddOutput(videoOutput) {
                captureSession.addInput(cameraInput)
                captureSession.addOutput(videoOutput)
            }
            print("Camera setting has completed.")
        } catch {
            print(error)
        }
        setupRTCCameraDevice(_device)
        captureSession.commitConfiguration()
    }
    
    private func setupRTCCameraDevice(_ device: AVCaptureDevice?) {
        socketManager?.webRtcClient.setupDevice(device!)
    }
    
    // input setting method
    private func setupInput(w: Int32, h: Int32) -> AVCaptureDevice?{
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInTripleCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .back)
        guard let device = discoverySession.devices.first else {
            return nil
        }
        
        let formats: [AVCaptureDevice.Format] = device.formats
        var selectedFormat: AVCaptureDevice.Format?
        
        var currentDiff = INT_MAX
        
        for format in formats {
           let dimension: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
           let pixelFormat: FourCharCode = CMFormatDescriptionGetMediaSubType(format.formatDescription)
           let diff = abs(w - dimension.width) + abs(h - dimension.height)
           if diff < currentDiff {
               selectedFormat = format
               currentDiff = diff
           } else if diff == currentDiff && pixelFormat == preferredOutputPixelFormat {
               selectedFormat = format
           }
        }
        self.deviceFormat = selectedFormat
        
        var maxFrameRate: Float64 = 0.0
        for fpsRange in  selectedFormat!.videoSupportedFrameRateRanges {
           maxFrameRate = fmax(maxFrameRate, fpsRange.maxFrameRate)
        }

//        let fps = Int(maxFrameRate)
        let fps = 10
        print("fps is \(fps)")
        do {
            try device.lockForConfiguration()
            device.activeFormat = selectedFormat!
            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
            device.unlockForConfiguration()
        } catch(let error) {
            print(error)
        }
        return device
    }
    
    //output setting method
    private func setupOutput() {
        let pixelFormats: Set<OSType> = Set([kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                                                kCVPixelFormatType_32BGRA
                                                               ])
        
        let availablePixelFormats = NSMutableOrderedSet(array: videoOutput.availableVideoPixelFormatTypes)
        availablePixelFormats.intersectSet(pixelFormats)

        let pixelFormat = availablePixelFormats.firstObject as? OSType ?? 0
        self.preferredOutputPixelFormat = pixelFormat
        
        if let format = self.deviceFormat {
            var mediaSubType: FourCharCode = CMFormatDescriptionGetMediaSubType(format.formatDescription)
            if availablePixelFormats.contains(mediaSubType) {
                if mediaSubType != preferredOutputPixelFormat {
                    self.preferredOutputPixelFormat = mediaSubType
                }
            } else {
                mediaSubType = self.preferredOutputPixelFormat
            }
        }
        
        let settings: [String: Any] = [
            String(kCVPixelBufferMetalCompatibilityKey): true,
            String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: self.preferredOutputPixelFormat),
        ]
        self.videoOutput.videoSettings = settings
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.setSampleBufferDelegate(self, queue: self.queue)
    }
    
    
    func startSession() {
        DispatchQueue.global(qos: .default).async {
            self.captureSession.startRunning()
                // qos : .utility = 이미지 전송,수송 시 사용. 꽤 긴 처리시간을 갖을 때 사용한다.
        }
        
        // websocket 통신 시작
        self.socketManager?.connect()
        self.socketManager?.connectRtc(clientId)
        
//        self._networkManager.runUploadImageSession()
    }
    
    func stopSession() {
        self.socketManager?.disconnect()
        self.socketManager?.disconnectRtc()
        self.captureSession.stopRunning()
    }
}

//MARK: -captureOutput 설정
extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !CameraSession.isUploaded else { return }
    
        CameraSession.isUploaded = true
        
        let cvImageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        guard cvImageBuffer != nil else { return }
        let ciImage = CIImage(cvImageBuffer: cvImageBuffer!).oriented(forExifOrientation: 6)
        var image = UIImage(ciImage: ciImage).resize(640, 640)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8)/* ?? image.pngData() */ else {
            return
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        print("Incoming video buffer at \(timestamp.seconds) seconds...")
        
//        DispatchQueue.main.async{
//            self._imageView?.image = image
//        }
        self.socketManager?.send(image: imageData)
//        self.isUploaded = isUpload
        
//        print("Upload is approaching...")

        
        let stringURL = "https://4049-116-32-21-139.ngrok-free.app/yl/img"
//        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        
//        AF.upload(multipartFormData: { multipartFormData in
//                    guard let image = UIImage(named: "chauchaudog.jpg"),
//                          let imageData = image.jpegData(compressionQuality: 1) ?? image.pngData(),
//                          let url = URL(string: stringURL)
//                    else {
//                        print("이미지 또는 URL을 불러올 수 없습니다.")
//                        return
//                    }
//                    multipartFormData.append(Data("user1".utf8), withName: "title")
//                    multipartFormData.append(imageData,
//                                             withName: "image",
//                                             fileName: "chauchaudog.jpg",
//                                             mimeType: "image/jpg")
//                }, to: stringURL, method: .post, headers: header)
//                .response{ response in
//                    guard let statusCode = response.response?.statusCode else {return }
//                            switch statusCode{
//                            case 200: 
//                                CameraSession.isUploaded = false
//                                /*
//                                DispatchQueue.main.async{
//                                    self._imageView?.image = image
//                                }
//                                 */
//                                print("이미지 전송 완료")
//                            default:
//                                print("오류발생")
//                            }
//                }
//
//
//            }
    
        
    }
}






extension UIImage {
    func resize(_ width: Int, _ height: Int) -> UIImage {
        // Keep aspect ratio
        let maxSize = CGSize(width: width, height: height)

        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: self.size,
            insideRect: .init(origin: .zero, size: maxSize)
        )
        let targetSize = availableRect.size

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Resize the image
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
//        print("화면 배율: \(UIScreen.main.scale)")// 배수
//        print("origin: \(self), resize: \(resized)")
        return resized
    }
    
}
