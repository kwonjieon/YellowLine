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




class CameraSession: NSObject {
    var mlModel : MLModel?
    // ai 모델
    var midasModel : MiDaS?
    let semaphore = DispatchSemaphore(value: 1)
    var delegate: CameraSessionDelegate?
    var captureSession = AVCaptureSession()
    var videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "videoQueue", qos: .userInteractive)

    var localView: UIView?
    //for test
    var midasView: UIImageView?
    
    let useMidas = false
    
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public var midasPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var deviceFormat: AVCaptureDevice.Format?
    var cameraDevice: AVCaptureDevice?
    
    //    var preferredOutputPixelFormat = FourCharCode("BGRA")
    var preferredOutputPixelFormat: FourCharCode = 0

    
    var isCapturing = false
    
    init(view: UIView/*, _ midasView: UIImageView*/){
        super.init()
        self.localView = view
//        self.midasView = midasView
        self.cameraDevice = setupInput(w: 1280, h:720)
    }
    
    // 이걸로 CameraSession + object detection 시작
    public func startVideo() {
        setup() { [self] success in
            if success {
                setUpBoundingBoxViews()
                self.filtRect = makeRectFilter(localView!.bounds.width, localView!.bounds.height, 0.07)
                // Add the video preview into the UI.
//                if let previewLayer = self.previewLayer {
//                    localView!.layer.addSublayer(previewLayer)
//                    self.previewLayer!.frame = self.localView!.bounds  // resize preview layer
//                }
                
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
        mlModel = try! ylyolov8s(configuration: MLModelConfiguration()).model
        if useMidas {
            midasModel = try! MiDaS(configuration: MLModelConfiguration())
        }

        yoloDetector = try! VNCoreMLModel(for: mlModel!)
        queue.async {
            self.captureSession = .init()
            self.videoOutput = .init()
            
            if self.useMidas {
                if let visionModel = try? VNCoreMLModel(for: self.midasModel!.model) {
                    self.midasVisionRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.visionRequestDidComplete)
                    self.midasVisionRequest?.imageCropAndScaleOption = .centerCrop
                } else {
                    fatalError("fail to create vision model")
                }
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
            complete = true
            self.isCapturing = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
                    complete = true
                    self.isCapturing = true
                }
            })
        default:
            break
        }
        return complete
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
        print("deviceFormat : \(selectedFormat)")
        // fps
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
    
    
    // MARK: 카메라 작동 시작
    func startSession() {
        if !self.captureSession.isRunning {
            DispatchQueue.global(qos: .default).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if self.captureSession.isRunning {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    
    // MARK: - object detection...
    var yoloDetector : VNCoreMLModel?
    var midasVisionModel : VNCoreMLModel?
    var detectionRequest : VNCoreMLRequest?

    let maxBoundingBoxViews = 100
    var boundingBoxViews = [BoundingBoxView]()
    var colors: [String: UIColor] = [:]
    
    private func setUpBoundingBoxViews() {
        // Ensure all bounding box views are initialized up to the maximum allowed.
        while boundingBoxViews.count < maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }
        
        // Retrieve class labels directly from the CoreML model's class labels, if available.
        guard let classLabels = mlModel!.modelDescription.classLabels as? [String] else {
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
        let request = VNCoreMLRequest(model: yoloDetector!, completionHandler: {
            [weak self] request, error in
            self?.processObservations(for: request, error: error)
        })
        // NOTE: BoundingBoxView object scaling depends on request.imageCropAndScaleOption https://developer.apple.com/documentation/vision/vnimagecropandscaleoption
        request.imageCropAndScaleOption = .scaleFill  // .scaleFit, .scaleFill, .centerCrop
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
//            let handler = VNImageRequestHandler(cgImage: resizedCGImage!)
            do {
//                DispatchQueue.main.async {
//                    self.midasView!.image = uiImage
//                }
                try handler.perform([visionRequest])
            } catch  {
                print(error)
            }
        } else {
            print("ERROR: visionRequestdidcomplete")
        }
    }
    
    // MARK: - Yolo
    //MARK: 속도 올리기 1. semaphore해제, 2. fps 증가, 3. 이미지 resize사용하지 않기.
    var currentBuffer: CVImageBuffer?
    func predict(_ cvImageBuffer : CVImageBuffer?){
        // Invoke a VNRequestHandler with that image
        if currentBuffer == nil {
            currentBuffer = cvImageBuffer
            self.semaphore.wait()
            let ciContext = CIContext()
            let ciImage = CIImage(cvImageBuffer: cvImageBuffer!)
                .oriented(forExifOrientation: 6)
            originalCIImage = ciImage
//            resizedCGImage = ciContext.createCGImage(ciImage, from: ciImage.extent)?.resize(size: CGSize(width: 640, height: 640))

            lazy var midasImg = ciContext.createCGImage(ciImage, from: ciImage.extent)?.resize(size: CGSize(width: 256, height: 256))
            lazy var midasHandler = VNImageRequestHandler(cgImage: midasImg!)
            
            //fast test for yolo
            lazy var handler = VNImageRequestHandler(ciImage: originalCIImage!)
            if UIDevice.current.orientation != .faceUp {  // stop if placed down on a table
                do {
                    if useMidas {
                        try midasHandler.perform([self.midasVisionRequest])
                    } else {
                        try handler.perform([visionRequest])

                    }
                } catch {
                    print(error)
                }
            }
            self.semaphore.signal()
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
            // TTS 실행.
            if !self.closeObjects.isEmpty {
                // 장애물이 탐지된 프레임이라면 +1
                TTSModelModule.ttsModule.objectCounts += 1
                self.queue.async {
                    TTSModelModule.ttsModule.processTTS(type: false, text: "전방에 장애물입니다.")
                }
            } else {
                TTSModelModule.ttsModule.objectCounts = 0
            }
            print("---")
            self.closeObjects.removeAll()

        }
    }

    // 가까운 거리 판별 사각형
    var filtRect : CGRect?
    var closeObjects : Set<String> = []// 탐지 물체들 넣는 객체
    var exceptObjects : Set<String> = ["crosswalk_yl", "red_yl", "green_yl"]
    
    // MARK:  Show
    func show(predictions: [VNRecognizedObjectObservation]) {
        let width = localView!.bounds.width
        let height = localView!.bounds.height

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
                rect = VNImageRectForNormalizedRect(rect, Int(width), Int(height))
//                    depthValue = 0.0

//
                var midX = rect.midX
                var midY = rect.midY
                if midX < 0 { midX = 0 }
                if midX >= width { midX = width }
                if midY < 0 { midY = 0 }
                if midY >= height { midY = height }
//
                var depthValue: Float?
                let midasX = Int(midX / width * 256)
                let midasY = Int(midY / height * 256)
//
//                    // 마이다스 이미지버퍼 상대적 좌표 지정
                if useMidas {
                    if self.depthCIImage != nil {
                        let bf = (self.depthPixelBuffer)!
                        let imgWidth = CGFloat(CVPixelBufferGetWidth(bf))
                        let imgHeight = CGFloat(CVPixelBufferGetHeight(bf))
                        
                        CVPixelBufferLockBaseAddress(bf, .readOnly)
                        let baseAddress = CVPixelBufferGetBaseAddress(bf)
                        let byteBuffer = baseAddress!.assumingMemoryBound(to: UInt8.self)
                        let bytePerRow = CVPixelBufferGetBytesPerRow(bf)
                        // read the data (returns value of type UInt8)
                        let dalue = byteBuffer[midasX + midasY * bytePerRow]
                        depthValue = 1.0 - Float(dalue) / 255.0
                        CVPixelBufferUnlockBaseAddress(bf, .readOnly)
                    }
                }

                let bestClass = prediction.labels[0].identifier
                let confidence = prediction.labels[0].confidence
                
                // filter boundary visualizing...
//                    let redSquare = UIView()
//                    redSquare.backgroundColor = UIColor(cgColor: CGColor(red: 63, green: 151, blue: 106, alpha: 0.35)) // 배경을 빨간색으로 설정
//                    redSquare.frame = filtRect!
//                    localView?.addSubview(redSquare)
                
//                    print("bestClass is : \(bestClass)")
                
                // 전방 필터 사각형 범위 내에 물체가 있으면 ( 가까이 물체가 있다면 )
                //  필터링 사각형
                if filtRect!.intersects(rect) {
                    if !exceptObjects.contains(bestClass) {
                        closeObjects.insert(bestClass)
                    }
                }

                // Show the bounding box.
                boundingBoxViews[i].show(frame: rect,
                                         label: String(format: "%@", bestClass),
                                         color: colors[bestClass] ?? UIColor.white,
                                         alpha: CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9))  // alpha 0 (transparent) to 1 (opaque) for conf threshold 0.2 to 1.0)
            } else {
                boundingBoxViews[i].hide()
            } // if prediction end...
        } // for end...
//        print(self.closeObjects)
    } // show end...
    
    func drawPoint(x : Int, y: Int, view: UIView){
        let radius = 8
        let dotPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: radius, height: radius))

        let layer = CAShapeLayer()
        layer.path = dotPath.cgPath
        layer.strokeColor = UIColor.blue.cgColor
        view.layer.addSublayer(layer)
    }
    
    private func makeRectFilter(_ w : CGFloat, _ h: CGFloat, _ ofs: CGFloat) -> CGRect {
        let widthLen = w * (1 - ofs)
        let heightLen = h * ofs
        let x = w * (ofs / 2)
        let y = h * (0.97 - ofs)
        return CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: widthLen, height: heightLen))
    }
}

//MARK: - captureOutput 설정
extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let cvImageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        //cvImageBuffer info : osType:875704438 w: 1280 h: 720
        guard cvImageBuffer != nil else { return }
//        print(CVPixelBufferGetPixelFormatType(cvImageBuffer!), CVPixelBufferGetWidth(cvImageBuffer!), CVPixelBufferGetHeight(cvImageBuffer!))
        delegate?.didWebRTCOutput(sampleBuffer)
        predict(cvImageBuffer)
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
