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
import CoreML
import CoreVideo
import Vision
//import Alamofire

protocol CameraSessionDelegate {
    func didWebRTCOutput(_ sampleBuffer: CMSampleBuffer)
}


let mlModel = try! ylyolov8s(configuration: MLModelConfiguration()).model
// ai 모델
let midasModel = try! MiDaS()

class CameraSession: NSObject {
    let semaphore = DispatchSemaphore(value: 1)
    var delegate: CameraSessionDelegate?
    var captureSession = AVCaptureSession()
    var videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "videoQueue", qos: .userInitiated)

    var localView: UIView?
    
    //for test
    var midasView: UIImageView?
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public var midasPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var deviceFormat: AVCaptureDevice.Format?
    var cameraDevice: AVCaptureDevice?
    
    //    var preferredOutputPixelFormat = FourCharCode("BGRA")
    var preferredOutputPixelFormat: FourCharCode = 0

    
    var isCapturing = false
    let clientId = "YLUser01"
    
    init(view: UIView, _ midasView: UIImageView){
        super.init()
        self.localView = view
        self.midasView = midasView
        setUpBoundingBoxViews()
        self.cameraDevice = setupInput(w: 1280, h:720)
    }
    
    // 이걸로 CameraSession + object detection 시작
    public func startVideo() {
        setup() { [self] success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.previewLayer {
                    localView!.layer.addSublayer(previewLayer)
                    self.previewLayer?.frame = self.localView!.bounds  // resize preview layer
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxViews {
                    box.addToLayer(self.localView!.layer)
                }
                
                print("setup complete")
                // Once everything is set up, we can start capturing live video.
                self.startSession()
            }
        }
    }
    
    func setup(completion: @escaping (Bool) -> Void) {
        queue.async {
            self.captureSession = .init()
            self.videoOutput = .init()
            // 뷰를 빈으로 등록해(ex:@State 같은 어노테이션) 나중에 이와같은 코드를 없애버리자.
            //            self._imageView = view

            
            if let visionModel = try? VNCoreMLModel(for: midasModel.model) {
                self.midasVisionRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.visionRequestDidComplete)
                self.midasVisionRequest?.imageCropAndScaleOption = .centerCrop
            } else {
                fatalError("fail to create vision model")
            }
            let success = self.setupCameraSession()
            DispatchQueue.main.async {
                completion(success)
            }
            
        }
    }
    // 카메라 권한 확인
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
        self.captureSession.sessionPreset = .photo //.photo, .hd1280x720
        
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
        do {
            try device.lockForConfiguration()
            device.activeFormat = selectedFormat!
            device.activeVideoMinFrameDuration = CMTimeMakeWithSeconds(1, preferredTimescale: Int32(10))
            device.unlockForConfiguration()
        } catch(let error) {
            print(error)
        }
        return device
    }
    
    //output setting method
    private func setupOutput() {
        self.videoOutput.videoSettings = .init()
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.setSampleBufferDelegate(self, queue: self.queue)
        
    }
    
    
    // 카메라 작동 시작
    func startSession() {
        if !self.captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if self.captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    
    // MARK: - object detection...
    var yoloDetector = try! VNCoreMLModel(for: mlModel)
    var midasVisionModel : VNCoreMLModel?
    var detectionRequest : VNCoreMLRequest?

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
    
    lazy var visionRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: yoloDetector, completionHandler: {
            [weak self] request, error in
            self?.processObservations(for: request, error: error)
        })
        // NOTE: BoundingBoxView object scaling depends on request.imageCropAndScaleOption https://developer.apple.com/documentation/vision/vnimagecropandscaleoption
        request.imageCropAndScaleOption = .centerCrop  // .scaleFit, .scaleFill, .centerCrop
        return request
    }()
    
    // MARK: - MIDAS
    /**
     입력: 256 *256이미지
     결과:256*256 grayscale(0~255값)이미지
     */
    var midasVisionRequest : VNCoreMLRequest!
    //for test midas
    var depthPixelBuffer : CVPixelBuffer?
    
    var depthCIImage: CIImage?
    var depthCIInput: CIImage?
    var originalCIImage : CIImage?
    var originalCGImage : CGImage?
    var resizedCGImage : CGImage?
    
    
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        // 여기서 pixelbuffer의 크기는 256*256크기임. (마이다스 인풋에 맞게 depthCIInput에 넣어놨기때문)
        if let predictions = request.results as? [VNPixelBufferObservation]
            , let pixelBuffer = predictions.first?.pixelBuffer
            , let bf = currentBuffer {
            depthPixelBuffer = pixelBuffer
            depthCIImage = CIImage(cvPixelBuffer: pixelBuffer)
            let uiImage = UIImage(ciImage: depthCIImage!)
            let handler = VNImageRequestHandler(ciImage: originalCIImage!)
            do {
                DispatchQueue.main.async {
                    self.midasView!.image = uiImage
                }
                try handler.perform([visionRequest])
            } catch  {
                print(error)
            }
        } else {
            print("ERROR: visionRequestdidcomplete")
        }
        self.semaphore.signal()
    }
    
    // MARK: - Yolo
    var currentBuffer: CVImageBuffer?
    func predict(_ cvImageBuffer : CVImageBuffer?){
        // Invoke a VNRequestHandler with that image
        if currentBuffer == nil {
            self.semaphore.wait()
            currentBuffer = cvImageBuffer

            let ciContext = CIContext()
            let ciImage = CIImage(cvImageBuffer: cvImageBuffer!)
                .oriented(forExifOrientation: 6)
            originalCIImage = ciImage
//            resizedCGImage = ciContext.createCGImage(ciImage, from: ciImage.extent)?.resize(size: CGSize(width: 640, height: 640))
            let midasImg = ciContext.createCGImage(ciImage, from: ciImage.extent)?.resize(size: CGSize(width: 256, height: 256))
            
            let midasHandler = VNImageRequestHandler(cgImage: midasImg!)
            if UIDevice.current.orientation != .faceUp {  // stop if placed down on a table
                do {
                    try midasHandler.perform([self.midasVisionRequest])
                } catch {
                    print(error)
                }
            }
            currentBuffer = nil
        } // if end
    } // predict end
    
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.show(predictions: results)
            } else {
                self.show(predictions: [])
            }
        }
    }

    // MARK:  Show
    func show(predictions: [VNRecognizedObjectObservation]) {
        let width = previewLayer!.bounds.width
        let height = previewLayer!.bounds.height
//        let width = localView!.bounds.width
//        let height = localView!.bounds.height

        var str = ""
        // ratio = videoPreview AR divided by sessionPreset AR
        var ratio: CGFloat = 1.0
        if captureSession.sessionPreset == .photo {
            ratio = (height / width) / (4.0 / 3.0)  // .photo
        } else {
            ratio = (height / width) / (16.0 / 9.0)  // .hd4K3840x2160, .hd1920x1080, .hd1280x720 etc.
        }
        
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
//                    print("first rect value : \(rect)")
                    
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
//                    print("second rect value : \(rect)")
                    rect = VNImageRectForNormalizedRect(rect, Int(width), Int(height))
//                    print("last rect value: \(rect)")
                    //                    print("\(self._ciImage?.extent.width), \(self._ciImage?.extent.height)\n Rect info: \(rect.minX), \(rect.minY)")
                    //그리기
//                    print("\(CVPixelBufferGetWidth(depthPixelBuffer!)), \(CVPixelBufferGetHeight(depthPixelBuffer!)), \(CVPixelBufferGetBytesPerRow(depthPixelBuffer!))")
                    var midX = rect.midX
                    var midY = rect.midY
                    // 점 그리기
                    drawPoint(x: Int(midX), y: Int(midY), view: localView!)
                    if midX < 0 { midX = 0 }
                    if midX >= width { midX = width }
                    if midY < 0 { midY = 0 }
                    if midY >= height { midY = height }
                    
                    var depthValue: Float?
                    let imgWidth = self.midasView!.bounds.width
                    let imgHeight = self.midasView!.bounds.height
                    let p_midasX = Int(midX / width * imgWidth)
                    let p_midasY = Int(midY / height * imgHeight)
                    let midasX = Int(midX / width * 256)
                    let midasY = Int(midY / height * 256)

                    depthValue = 0.0
                    // 마이다스 이미지 좌표 지정
                    if self.depthCIImage != nil {
                        let bf = (self.depthPixelBuffer)!
                        let imgWidth = CGFloat(CVPixelBufferGetWidth(bf))
                        let imgHeight = CGFloat(CVPixelBufferGetHeight(bf))
                        //draw start
                        let radius = 8
                        let dotPath = UIBezierPath(ovalIn: CGRect(x: midasX, y: midasY, width: radius, height: radius))
                        let layer = CAShapeLayer()
                        layer.path = dotPath.cgPath
                        layer.strokeColor = UIColor.blue.cgColor
                        self.midasView!.layer.addSublayer(layer)
                        //draw end
                        
                        CVPixelBufferLockBaseAddress(bf, .readOnly)
                        let baseAddress = CVPixelBufferGetBaseAddress(bf)
                        let byteBuffer = baseAddress!.assumingMemoryBound(to: UInt8.self)
                        let bytePerRow = CVPixelBufferGetBytesPerRow(bf)
                        // read the data (returns value of type UInt8)
                        let dalue = byteBuffer[midasX + midasY * bytePerRow]
                        depthValue = 1.0 - Float(dalue) / 255.0
                        CVPixelBufferUnlockBaseAddress(bf, .readOnly)
                    }
                    let bestClass = prediction.labels[0].identifier
                    let confidence = prediction.labels[0].confidence
                    
//                    // bestClass != 신호등이 아니면서 멀리에 있는 것들
//                    if  bestClass != "" && depthValue! >= 0.4 {
//                        boundingBoxViews[i].hide()
//                        continue
//                    }
                    
                    // 가까운 것들만 내려오면, class와 depthValue값을 배열에 넣고
                    // depthValue로 정렬해서 prediction end 다음 줄에
                    // TTS실행 시키는 코드 작성.
                    // Show the bounding box.
                    boundingBoxViews[i].show(frame: rect,
                                             label: String(format: "%@ %.1f %.2f", bestClass, confidence * 100, depthValue!),
                                             color: colors[bestClass] ?? UIColor.white,
                                             alpha: CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9))  // alpha 0 (transparent) to 1 (opaque) for conf threshold 0.2 to 1.0)
                } //confidence >= .5 end
            } else {
                boundingBoxViews[i].hide()
            } // prediction end...
            
            //여기다가 TTS 모듈 넣는게 어떨까 싶음.
            
        } // show end...
    }
    
    func drawPoint(x : Int, y: Int, view: UIView){
        let radius = 8
        let dotPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: radius, height: radius))

        let layer = CAShapeLayer()
        layer.path = dotPath.cgPath
        layer.strokeColor = UIColor.blue.cgColor
        view.layer.addSublayer(layer)
    }
}

//MARK: - captureOutput 설정
extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        let cvImageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        //cvImageBuffer info : osType:875704438 w: 1280 h: 720
        guard cvImageBuffer != nil else { return }
//        print(CVPixelBufferGetPixelFormatType(cvImageBuffer!), CVPixelBufferGetWidth(cvImageBuffer!), CVPixelBufferGetHeight(cvImageBuffer!))
        predict(cvImageBuffer)
        delegate?.didWebRTCOutput(sampleBuffer)
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
}


extension CGImage {
    func resize(size:CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel


        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}
/**
 
 https://www.kaggle.com/code/takuyasukegawa/yolov8-midas-find-the-nearest-cars
 */
