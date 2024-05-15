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
import CoreMedia
import CoreML
import Vision

//import Alamofire

protocol CameraSessionDelegate {
    func didWebRTCOutput(_ sampleBuffer: CMSampleBuffer)
    func didSampleOutput(_ ciImage: CIImage)
}

let mlModel = try! yolov7_tiny(configuration: MLModelConfiguration()).model
class CameraSession: NSObject {
    var delegate: CameraSessionDelegate?
    var captureSession = AVCaptureSession()
//    var videoOutput: AVCaptureVideoDataOutput
    var videoOutput = AVCaptureVideoDataOutput()
    var imgUrl: String!
    let queue = DispatchQueue(label: "videoQueue")
    var _image: UIImage?
    var _imageView: UIImageView? // videoPreview
//    var secImageView: UIImageView?
//    var subscriptions = Set<>()
    public var previewLayer: AVCaptureVideoPreviewLayer?
    var deviceFormat: AVCaptureDevice.Format?
    var cameraDevice: AVCaptureDevice?
    
//    var preferredOutputPixelFormat = FourCharCode("BGRA")
    var preferredOutputPixelFormat: FourCharCode = 0

    //networkmanager는 websocket을 사용하기 때문에 현재 사용안함. 나중에 추가로 서버와 통신할 때 간단한 통신작업만 추가할예정.
//    let _networkManager = NetworkManager(url : URL(string: "ws://0.tcp.jp.ngrok.io:15046/yl/ws/"))
//    let socketManager: WebSocketManager?
    
    var isCapturing = false
    let clientId = "YLUser01"
    
    init(view: UIImageView?){
        super.init()
        //url도 websocket 주소로 바꿀계획.
        setUpBoundingBoxViews()
        self.cameraDevice = setupInput(w: 1280, h:720)
        self._imageView = view
//        self.secImageView = view2
    }

    // 이걸로 CameraSession + object detection 시작
    public func startVideo() {
        setup() { [self] success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.previewLayer {
                    _imageView!.layer.addSublayer(previewLayer)
                    self.previewLayer?.frame = self._imageView!.bounds  // resize preview layer
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxViews {
                    box.addToLayer(self._imageView!.layer)
                }
                
                print("setup complete")
                // Once everything is set up, we can start capturing live video.
                self.startSession()
            }
        }
    }
    
    func setup(completion: @escaping (Bool) -> Void) {
        self.imgUrl = "https://145b-182-222-253-136.ngrok-free.app/yl/img"
        queue.async {
            self.captureSession = .init()
            self.videoOutput = .init()
            // 뷰를 빈으로 등록해(ex:@State 같은 어노테이션) 나중에 이와같은 코드를 없애버리자.
//            self._imageView = view
            //run websocket
    //        self.socketManager = WebSocketManager(view: self._imageView!)
//            self.detection = Detection((self.previewLayer?.bounds.width)!, (self.previewLayer?.bounds.height)!)
            let model = try! VNCoreMLModel(for: yolov7_tiny(configuration: MLModelConfiguration()).model)
            self.detectionRequest = VNCoreMLRequest(model: model)
            let success = self.setupCameraSession()
            DispatchQueue.main.async {
                completion(success)
            }

        }
    }
    
    
    func checkCameraAuthor() -> Bool{
        var complete = false
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
//            setupCameraSession()
            complete = true
            self.isCapturing = true
            //            self.setupCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
//                    setupCameraSession()
                    complete = true
                    self.isCapturing = true
                }
            })
        default:
            break
        }
        return complete
    }

    private func setupRTCCameraDevice(_ device: AVCaptureDevice?) {
//        socketManager?.webRtcClient.setupDevice(device!)
    }
    //MARK: -세팅:카메라 세션
    func setupCameraSession() -> Bool {
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = .high
        // input setting

        
        //output setting
        setupOutput()
        
        //add input and output
        do {
            let cameraInput = try AVCaptureDeviceInput(device: cameraDevice!)
            if captureSession.canAddInput(cameraInput) && captureSession.canAddOutput(videoOutput) {
                captureSession.addInput(cameraInput)
                captureSession.addOutput(videoOutput)
            }
            print("Camera setting has completed.")
        } catch {
            print(error)
            return false
        }
        
//        setupRTCCameraDevice(cameraDevice)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        captureSession.commitConfiguration()
        return true
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
        if !self.captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }

        
        // websocket 통신 시작
//        self.socketManager?.connect()
//        self.socketManager?.connectRtc(clientId)
        
//        self._networkManager.runUploadImageSession()
    }
    
    func stopSession() {
        if self.captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
//        self.socketManager?.disconnect()
//        self.socketManager?.disconnectRtc()
    }
// MARK: - object detection...
    var detector = try! VNCoreMLModel(for: mlModel)
//    let model = try! VNCoreMLModel(for: yolov7_tiny(configuration: MLModelConfiguration()).model)
    var detectionRequest : VNCoreMLRequest?
    var currentBuffer: CVPixelBuffer?
    var framesDone = 0
    var t0 = 0.0  // inference start
    var t1 = 0.0  // inference dt
    var t2 = 0.0  // inference dt smoothed
    var t3 = CACurrentMediaTime()  // FPS start
    var t4 = 0.0  // FPS dt smoothed
    
    let maxBoundingBoxViews = 100
    var boundingBoxViews = [BoundingBoxView]()
    var colors: [String: UIColor] = [:]

    private func setUpBoundingBoxViews() {
        // Ensure all bounding box views are initialized up to the maximum allowed.
        while boundingBoxViews.count < maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }

        // Retrieve class labels directly from the CoreML model's class labels, if available.
        guard let classLabels = mlModel.modelDescription.classLabels as? [String] else {
            fatalError("Class labels are missing from the model description")
        }

        // Assign random colors to the classes.
        for label in classLabels {
            if colors[label] == nil {  // if key not in dict
                colors[label] = UIColor(red: CGFloat.random(in: 0...1),
                        green: CGFloat.random(in: 0...1),
                        blue: CGFloat.random(in: 0...1),
                        alpha: 0.6)
            }
        }
    }

   /*
    // sublayers에서 image를 통합하기 위한 뷰. 단점 -> 좀 느림
    func startVideo(_ sampleBuffer: CMSampleBuffer) -> UIImage?{
        let cvImageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        guard cvImageBuffer != nil else { return nil}
        let ciImage = CIImage(cvImageBuffer: cvImageBuffer!).oriented(forExifOrientation: 6)
        let predicts = self.predict1(ciImage)
        let processed = self.processObservations1(for: predicts)
        
        let labeledImage = self.labeler.labelImage(image: UIImage(ciImage: ciImage), observations: processed)!
        return labeledImage
    }
    
    
    func predict1(_ ciImage: CIImage) -> [VNObservation] {

        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        do{
            // 예측진행
            try handler.perform([self.detectionRequest!])
            // show results
            let observations = self.detectionRequest!.results!
            
            return observations
            
        }catch let error{
            fatalError("failed to detect: \(error)")
        }
    }
    
    
    func processObservations1(for request: [VNObservation]) -> [ProcessedObservation] {
        var processedObservations:[ProcessedObservation] = []
        for observation in request where observation is VNRecognizedObjectObservation {
            
            let objectObservation = observation as! VNRecognizedObjectObservation
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int((self._imageView?.bounds.width)!), Int((self._imageView?.bounds.height)!))
            
            let flippedBox = CGRect(x: objectBounds.minX, y: (self._imageView?.bounds.height)! - objectBounds.maxY, width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
            
            let label = objectObservation.labels.first!.identifier
            // 사각형 지정 완료했으면, 라벨, 추측값, 바운딩박스.
            let processedOD = ProcessedObservation(label: label, confidence: objectObservation.confidence, boundingBox: flippedBox)
            
            processedObservations.append(processedOD)
        }

        
        return processedObservations
    }
    */
    
    // MARK: - without image
    
    lazy var visionRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: detector, completionHandler: {
            [weak self] request, error in
            self?.processObservations(for: request, error: error)
        })
        // NOTE: BoundingBoxView object scaling depends on request.imageCropAndScaleOption https://developer.apple.com/documentation/vision/vnimagecropandscaleoption
        request.imageCropAndScaleOption = .scaleFill  // .scaleFit, .scaleFill, .centerCrop
        return request
    }()

    
    func predict(_ ciImage: CIImage){
        // Invoke a VNRequestHandler with that image
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: imageOrientation, options: [:])
        let handler = VNImageRequestHandler(ciImage: ciImage)
        if UIDevice.current.orientation != .faceUp {  // stop if placed down on a table
            t0 = CACurrentMediaTime()  // inference start
            do {
                try handler.perform([visionRequest])
                let observations = self.visionRequest.results!
            } catch {
                print(error)
            }
            t1 = CACurrentMediaTime() - t0  // inference dt
        }
    }
    
    
    
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.show(predictions: results)
            } else {
                self.show(predictions: [])
            }
        }

    }

    
    func show(predictions: [VNRecognizedObjectObservation]) {
        let width = self._imageView!.bounds.width  // 375 pix
        let height = self._imageView!.bounds.height  // 812 pix
        var str = ""
        
        // ratio = videoPreview AR divided by sessionPreset AR
        var ratio: CGFloat = 1.0
        if captureSession.sessionPreset == .photo {
            ratio = (height / width) / (4.0 / 3.0)  // .photo
        } else {
            ratio = (height / width) / (16.0 / 9.0)  // .hd4K3840x2160, .hd1920x1080, .hd1280x720 etc.
        }
        
        // date
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        let sec_day = Double(hour) * 3600.0 + Double(minutes) * 60.0 + Double(seconds) + Double(nanoseconds) / 1E9  // seconds in the day
        
        for i in 0..<boundingBoxViews.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                var rect = prediction.boundingBox  // normalized xywh, origin lower left
                switch UIDevice.current.orientation {
                case .portraitUpsideDown:
                    rect = CGRect(x: 1.0 - rect.origin.x - rect.width,
                                  y: 1.0 - rect.origin.y - rect.height,
                                  width: rect.width,
                                  height: rect.height)
                case .landscapeLeft:
                    rect = CGRect(x: rect.origin.y,
                                  y: 1.0 - rect.origin.x - rect.width,
                                  width: rect.height,
                                  height: rect.width)
                case .landscapeRight:
                    rect = CGRect(x: 1.0 - rect.origin.y - rect.height,
                                  y: rect.origin.x,
                                  width: rect.height,
                                  height: rect.width)
                case .unknown:
                    print("The device orientation is unknown, the predictions may be affected")
                    fallthrough
                default: break
                }
                
                if ratio >= 1 { // iPhone ratio = 1.218
                    let offset = (1 - ratio) * (0.5 - rect.minX)
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: offset, y: -1)
                    rect = rect.applying(transform)
                    rect.size.width *= ratio
                } else { // iPad ratio = 0.75
                    let offset = (ratio - 1) * (0.5 - rect.maxY)
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: offset - 1)
                    rect = rect.applying(transform)
                    rect.size.height /= ratio
                }
                
                rect = VNImageRectForNormalizedRect(rect, Int(width), Int(height))
                
                // The labels array is a list of VNClassificationObservation objects,
                // with the highest scoring class first in the list.
                let bestClass = prediction.labels[0].identifier
                let confidence = prediction.labels[0].confidence
                // print(confidence, rect)  // debug (confidence, xywh) with xywh origin top left (pixels)
                
                // Show the bounding box.
                boundingBoxViews[i].show(frame: rect,
                                         label: String(format: "%@ %.1f", bestClass, confidence * 100),
                                         color: colors[bestClass] ?? UIColor.white,
                                         alpha: CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9))  // alpha 0 (transparent) to 1 (opaque) for conf threshold 0.2 to 1.0)
            } else {
                boundingBoxViews[i].hide()
            }
//            UIGraphicsBeginImageContextWithOptions(self._imageView!.bounds.size, false, 0.0)
//            if let context = UIGraphicsGetCurrentContext() {
//                self._imageView!.layer.render(in: context)
//            }
//            let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//            secImageView!.image = capturedImage
        }
    }
}


//MARK: - captureOutput 설정
extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        startCapture(sampleBuffer)
        
        //        guard !CameraSession.isUploaded else { return }
        //
        ////        CameraSession.isUploaded = true
        //
        let cvImageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        guard cvImageBuffer != nil else { return }
        let ciImage = CIImage(cvImageBuffer: cvImageBuffer!).oriented(forExifOrientation: 6)
        predict(ciImage)
        delegate?.didWebRTCOutput(sampleBuffer)
        //CameraSession + WebRTC확인 용으로 넣은 delegate protocol.
        delegate?.didSampleOutput(ciImage)
//        var image = startVideo(sampleBuffer)
//        DispatchQueue.main.async {
//            self.secImageView!.image = image
//        }
//                var image = UIImage(ciImage: ciImage).resize(640, 640)
//        
//                guard let imageData = image.jpegData(compressionQuality: 0.8)/* ?? image.pngData() */ else {
//                    return
//                }
        //
        //        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        ////        print("Incoming video buffer at \(timestamp.seconds) seconds...")
        //
//                DispatchQueue.main.async{
////                    var uiimage = self.detection?.startVideo(sampleBuffer)
////                    self._imageView?.image = uiimage
//                    self._imageView?.image = image
//                }
        //        self.socketManager?.send(image: imageData)
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
