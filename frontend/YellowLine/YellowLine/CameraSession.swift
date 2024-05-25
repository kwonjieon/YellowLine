//
//  Sessions.swift
//  YellowLine
//
//  Created by 이종범 on 4/8/24.
//

import Foundation
import AVFoundation
import Accelerate
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

// ai 모델
let mlModel = try! yolov8s(configuration: MLModelConfiguration()).model
//let midasModel = try! midas_small(configuration: MLModelConfiguration()).model
let midasModel = try! MiDaS()
//let midasModel = try! FCRNFP16(configuration: MLModelConfiguration())

class CameraSession: NSObject {
    let semaphore = DispatchSemaphore(value: 1)
    var delegate: CameraSessionDelegate?
    var captureSession = AVCaptureSession()
    //    var videoOutput: AVCaptureVideoDataOutput
    var videoOutput = AVCaptureVideoDataOutput()
    var imgUrl: String!
    let queue = DispatchQueue(label: "videoQueue")
    var _ciImage: CIImage?
    //    var _cvpixelbuffer: CVPixelBuffer?
    var _imageView: UIImageView? // videoPreview
    var secImageView: UIImageView?
    //    var subscriptions = Set<>()
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public var midasPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var deviceFormat: AVCaptureDevice.Format?
    var cameraDevice: AVCaptureDevice?
    
    //    var preferredOutputPixelFormat = FourCharCode("BGRA")
    var preferredOutputPixelFormat: FourCharCode = 0
    
    //networkmanager는 websocket을 사용하기 때문에 현재 사용안함. 나중에 추가로 서버와 통신할 때 간단한 통신작업만 추가할예정.
    //    let _networkManager = NetworkManager(url : URL(string: "ws://0.tcp.jp.ngrok.io:15046/yl/ws/"))
    //    let socketManager: WebSocketManager?
    
    var isCapturing = false
    let clientId = "YLUser01"
    
    init(view: UIImageView?, view2: UIImageView?){
        super.init()
        //url도 websocket 주소로 바꿀계획.
        setUpBoundingBoxViews()
        
        self.cameraDevice = setupInput(w: 1280, h:720)
        self._imageView = view
        self.secImageView = view2
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
                
                if let midasPreviewLayer = self.midasPreviewLayer{
                    secImageView!.layer.addSublayer(midasPreviewLayer)
                    self.midasPreviewLayer?.frame = self.secImageView!.bounds  // resize preview layer
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
            let model = try! VNCoreMLModel(for: yolov8s(configuration: MLModelConfiguration()).model)
            //            let midasModel = try! VNCoreMLModel(for: midas_small(configuration: MLModelConfiguration()).model)
            
            if let visionModel = try? VNCoreMLModel(for: midasModel.model) {
                self.midasVisionModel = visionModel
                self.midasVisionRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.visionRequestDidComplete)
                self.midasVisionRequest?.imageCropAndScaleOption = .centerCrop
            } else {
                fatalError("fail to create vision model")
            }
            
            //            self.yoloRequest = VNCoreMLRequest(model: model)
            
            self.detectionRequest = VNCoreMLRequest(model: model)
            //            self.midasVisionRequest = VNCoreMLRequest(model: midasModel/*, completionHandler: self.visionRequestDidComplete*/)
            //            self.midasVisionRequest?.imageCropAndScaleOption = .centerCrop
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
        self.captureSession.sessionPreset = .photo
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
//                self.socketManager?.disconnect()
//                self.socketManager?.disconnectRtc()
    }
    
    
    // MARK: - object detection...
    var detector = try! VNCoreMLModel(for: mlModel)
    var midasVisionModel : VNCoreMLModel?
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
    
    // MARK: - MIDAS
    var midasVisionRequest : VNCoreMLRequest!
    //    var midasDetector = try! VNCoreMLModel(for: midasModel.model)
    var depthCIImage: CIImage?
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let predictions = request.results as? [VNPixelBufferObservation],
           let pixelBuffer = predictions.first?.pixelBuffer {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            self.depthCIImage = ciImage
            let uiImage = UIImage(ciImage: ciImage)
            
            do {
                let handler = VNImageRequestHandler(ciImage: self._ciImage!)
                DispatchQueue.main.async {
                    self.secImageView?.image = uiImage
                }
                try handler.perform([visionRequest])
                //d
            } catch  {
                print(error)
            }
        } else {
            print("ERROR: visionRequestdidcomplete")
        }
        self.semaphore.signal()
    }
    
    
    // MARK: - Yolo
    /**
     이미지의 전체 픽셀사이즈를 구하는 법. (cgimage이용)
     let image = UIImage(named: "test")
     let width = image?.cgImage.width // Pixel width
     let height = image?.cgImage.height // Pixel height
     let imageSize = CGSize(width: width, height: height) //Image Pixel Size
     print("Image Pixel Size: \(imageSize)")
     */
    
    func predict(_ pixelBuffer: CVImageBuffer){
        // Invoke a VNRequestHandler with that image
        //        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: imageOrientation, options: [:])
        self.semaphore.wait()
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(forExifOrientation: 6)
        self._ciImage = ciImage
        let midasHandler = VNImageRequestHandler(ciImage: ciImage)
        if UIDevice.current.orientation != .faceUp {  // stop if placed down on a table
            do {
                try midasHandler.perform([self.midasVisionRequest])
                //                try handler.perform([visionRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func midasProcessObservation(for request: VNRequest, error: Error?){
        print(request)
    }
    
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                //                print("====predictions\n", results)
                self.show(predictions: results)
            } else {
                self.show(predictions: [])
            }
        }
    }
    
    func show(predictions: [VNRecognizedObjectObservation]) {
        let width = self._imageView!.bounds.width  // 375 pix
        let height = self._imageView!.bounds.height  // 812 pix
        let midasWidth = self.secImageView!.bounds.width
        let midasHeight = self.secImageView!.bounds.height
//        print("view width: \(width), view height : \(height)")

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
                if prediction.confidence >= 0.5 {
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
//                    print("\(self._ciImage?.extent.width), \(self._ciImage?.extent.height)\n Rect info: \(rect.minX), \(rect.minY)")
                    //그리기
                    let midX = rect.midX
                    let midY = rect.midY
                    
                     
                    var depthValue: CGFloat?
                    
                    // 마이다스 이미지 좌표 지정
                    if self.depthCIImage != nil {
                        let bf = (self.depthCIImage?.pixelBuffer)!
                        let imgWidth = CVPixelBufferGetWidth(bf)
                        let imgHeight = CVPixelBufferGetHeight(bf)
                        let midasX = Int((midX / width)) * imgWidth
                        let midasY = Int(midY / height) * imgHeight
                        //1
                        let context = CIContext()
                        let depthPixel = context.createCGImage(self.depthCIImage!,from: CGRect(x: midasX, y: midasY, width: 1, height: 1))
                        if depthPixel == nil { break }
                        let pixelData = CFDataGetBytePtr(depthPixel?.dataProvider?.data)
                        let dalue = pixelData!.pointee
                        depthValue = CGFloat(dalue) / 255.0
                        //2
//                        CVPixelBufferLockBaseAddress(bf, .readOnly)
//                        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(bf), to: UnsafeMutablePointer<Float>.self)
//
//                        print(floatBuffer[midasX+midasY])
//                        CVPixelBufferUnlockBaseAddress(bf, .readOnly)
                    }
                    
                    // The labels array is a list of VNClassificationObservation objects,
                    // with the highest scoring class first in the list.
                    
//                    if depthValue! >= 0.6 {
//                        boundingBoxViews[i].hide()
//                        break
//                    }
                    let bestClass = prediction.labels[0].identifier
//                    print("\(bestClass): \(depthValue)")
                    let confidence = prediction.labels[0].confidence
//                    print(confidence, rect)  // debug (confidence, xywh) with xywh origin top left (pixels)
                    
                    // Show the bounding box.
                    boundingBoxViews[i].show(frame: rect,
                                             label: String(format: "%@ %.1f", bestClass, confidence * 100),
                                             color: colors[bestClass] ?? UIColor.white,
                                             alpha: CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9))  // alpha 0 (transparent) to 1 (opaque) for conf threshold 0.2 to 1.0)
                }
                
            } else {
                boundingBoxViews[i].hide()
            }
        }
    }
    
    func drawPoint(x : Int, y: Int, view: AVCaptureVideoPreviewLayer){
        let radius = 8

        let dotPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: radius, height: radius))

        let layer = CAShapeLayer()
        layer.path = dotPath.cgPath
        layer.strokeColor = UIColor.blue.cgColor
        view.addSublayer(layer)
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
        predict(cvImageBuffer!)

        delegate?.didWebRTCOutput(sampleBuffer)
        
        //CameraSession + WebRTC확인 용으로 넣은 delegate protocol.
        delegate?.didSampleOutput(ciImage)

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
    
    // 사용법: image!.resized(to: CGSize(width: 250, height: 250))
    func resized(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image
    }

    func normalized() -> [Float32]? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        let w = cgImage.width
        let h = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * w
        let bitsPerComponent = 8
        var rawBytes: [UInt8] = [UInt8](repeating: 0, count: w * h * 4)
        rawBytes.withUnsafeMutableBytes { ptr in
            if let cgImage = self.cgImage,
                let context = CGContext(data: ptr.baseAddress,
                                        width: w,
                                        height: h,
                                        bitsPerComponent: bitsPerComponent,
                                        bytesPerRow: bytesPerRow,
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                let rect = CGRect(x: 0, y: 0, width: w, height: h)
                context.draw(cgImage, in: rect)
            }
        }
        var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: w * h * 3)
        // normalize the pixel buffer
        // see https://pytorch.org/hub/pytorch_vision_resnet/ for more detail
        for i in 0 ..< w * h {
            normalizedBuffer[i] = (Float32(rawBytes[i * 4 + 0]) / 255.0 - 0.485) / 0.229 // R
            normalizedBuffer[w * h + i] = (Float32(rawBytes[i * 4 + 1]) / 255.0 - 0.456) / 0.224 // G
            normalizedBuffer[w * h * 2 + i] = (Float32(rawBytes[i * 4 + 2]) / 255.0 - 0.406) / 0.225 // B
        }
        return normalizedBuffer
    }
}

extension CVPixelBuffer {
    func normalized(_ width: Int, _ height: Int) -> [Float]? {
        let w = CVPixelBufferGetWidth(self)
        let h = CVPixelBufferGetHeight(self)
        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)
        assert(pixelBufferType == kCVPixelFormatType_32BGRA)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let bytesPerPixel = 4
        let croppedImageSize = min(w, h)
        CVPixelBufferLockBaseAddress(self, .readOnly)
        let oriX = w > h ? (w - h) / 2 : 0
        let oriY = h > w ? (h - w) / 2 : 0
        guard let baseAddr = CVPixelBufferGetBaseAddress(self)?.advanced(by: oriY * bytesPerRow + oriX * bytesPerPixel) else {
            return nil
        }
        var inBuff = vImage_Buffer(data: baseAddr, height: UInt(croppedImageSize), width: UInt(croppedImageSize), rowBytes: bytesPerRow)
        guard let dstData = malloc(width * height * bytesPerPixel) else {
            return nil
        }
        var outBuff = vImage_Buffer(data: dstData, height: UInt(height), width: UInt(width), rowBytes: width * bytesPerPixel)
        let err = vImageScale_ARGB8888(&inBuff, &outBuff, nil, vImage_Flags(0))
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        if err != kvImageNoError {
            free(dstData)
            return nil
        }
        var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: width * height * 3)
        for i in 0 ..< width * height {
            normalizedBuffer[i] = Float32(dstData.load(fromByteOffset: i * 4 + 0, as: UInt8.self)) / 255.0  // R
            normalizedBuffer[width * height + i] = Float32(dstData.load(fromByteOffset: i * 4 + 1, as: UInt8.self)) / 255.0 // G
            normalizedBuffer[width * height * 2 + i] = Float32(dstData.load(fromByteOffset: i * 4 + 2, as: UInt8.self)) / 255.0 // B
        }
        free(dstData)
        return normalizedBuffer
    }
}

/**
 
 https://www.kaggle.com/code/takuyasukegawa/yolov8-midas-find-the-nearest-cars
 */
