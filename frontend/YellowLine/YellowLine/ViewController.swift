//
//  ViewController.swift
//  videoTest
//
//  Created by 정성희 on 3/25/24.
//

import AVKit
import UIKit
import AVFoundation
import Alamofire
import Combine


class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
     @IBOutlet var imageView: UIImageView!
    
    var captureSession: AVCaptureSession!
    var videoOutput: AVCaptureVideoDataOutput!
    var subscriptions = Set<AnyCancellable>()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    let queue = DispatchQueue(label: "videoQueue")
    
    var isUploading = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        
        checkCameraAuthor()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
}



//MARK: -비디오를 이미지로 변환하는 작업 수행 후 보냄
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func imageRequest(){

    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !self.isUploading else {
            return
        }
        
        isUploading = true
        
        let cvImageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        guard cvImageBuffer != nil else { return }

//        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
//        let ciImage = CIImage(cvImageBuffer: cvImageBuffer!, options: attachments as! [CIImageOption : Any] ).oriented(forExifOrientation: 6)
        let ciImage = CIImage(cvImageBuffer: cvImageBuffer!).oriented(forExifOrientation: 6)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        print("Incoming video buffer at \(timestamp.seconds) seconds...")
        
//        DispatchQueue.main.async {
//            self.imageView.image = image
//        }
        
        uploadWithCombine(image: image)
            .sink( receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    self.isUploading = false
                    break // 성공적으로 완료
                case .failure(let error):
                    print(error.localizedDescription) // 오류 처리
                }
            }, receiveValue: { [weak self] uploadedImage in
                self?.isUploading = false
                DispatchQueue.main.async {
                    self?.imageView.image = uploadedImage
                }
            })
            .store(in: &subscriptions)
        //MARK: 이미지 보내기 & UI표시하기.
//        DispatchQueue.main.async{
////            self.imageView = UIImageView(image: image)
//            Task{
//                await self.upload(image: image)
//            }
////            self.imageView.image = result
//        }
//        upload(image: image)
    }
    
    
    
    private func createBody(parameters: [String: String],
                            boundary: String,
                            data: Data,
                            mimeType: String,
                            filename: String) -> Data {
        var body = Data()
        let imgDataKey = "image"
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.append(boundaryPrefix.data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(imgDataKey)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--".appending(boundary.appending("--")).data(using: .utf8)!)
        
        return body as Data
    }
    
}



//MARK: -권한 설정 및 카메라 설정
/**
 camera input, camera output을 설정한다.
 */
extension ViewController {
    func checkCameraAuthor() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
                    self.setupCamera()
                }
            })
        default:
            break
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: self.queue)
        captureSession.beginConfiguration()
        
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInTripleCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .back)
        //        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard let captureDevice = discoverySession.devices.first else {
            return
        }

        do {
            try captureDevice.lockForConfiguration()
            
            captureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(5))
            captureDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(5))
            
            captureDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.sessionPreset = .photo
            if captureSession.canAddInput(cameraInput) && captureSession.canAddOutput(videoOutput) {
                captureSession.addInput(cameraInput)
                captureSession.addOutput(videoOutput)
                captureSession.commitConfiguration()
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            self.previewView.layer.addSublayer(videoPreviewLayer)
            captureSession.commitConfiguration()
            
        } catch {
            print(error)
        }
        DispatchQueue.global(qos: .default).async {
            self.captureSession.startRunning()
                // qos : .utility = 이미지 전송,수송 시 사용. 꽤 긴 처리시간을 갖을 때 사용한다.
        }
//        DispatchQueue.main.async {
//            self.videoPreviewLayer.frame = self.previewView.bounds
//        }
        
    }
}


//MARK: -이미지 캡처
extension ViewController: AVCapturePhotoCaptureDelegate {
    /*
    @IBAction func takePhoto(_ sender: Any) {
        photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self as AVCapturePhotoCaptureDelegate)
    }
    */
    /*
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)
        // 이미지뷰에 이미지 설정
    }
     */
    
//    DispatchQueue.global(qos: .userInteractive).async { // [weak var] in
        
}

//MARK: -버튼식 파일보내기. Alamofire패키지 깃허브에 따와야함
//https://github.com/Alamofire/Alamofire.git 로 패키지 추가하자.
//http 연결 시 App transport -> exception domain -> YES로 info설정 변경해줘야함.
extension ViewController {
    func uploadWithCombine(image: UIImage) -> AnyPublisher<UIImage?, Error>{
        guard let imageData = image.jpegData(compressionQuality: 0.7) ?? image.pngData() else {
            return Fail(error: NSError(domain: "com.example.error", code: -1, userInfo: nil)).eraseToAnyPublisher()
        }
        
        let stringURL = "https://5be8-182-222-253-136.ngrok-free.app/yl/img"
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        
        let nowDate = Date()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy/MM/dd_HH:mm:ss"
        let convertedDate = dateFormat.string(from: nowDate)
        
        return Future<UIImage?, Error> { promise in
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(Data("user1".utf8), withName: "title")
                multipartFormData.append(imageData,
                                         withName: "image",
                                         fileName: "user1_\(convertedDate).jpeg",
                                         mimeType: "image/jpeg")
            }, to: stringURL, method: .post, headers: header)
            .responseData{ response in
                switch response.result {
                case .success(let data):
                    self.isUploading = false
                    let result = UIImage(data: data)
                    promise(.success(result))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func upload(image: UIImage){
        let stringURL = "https://5be8-182-222-253-136.ngrok-free.app/yl/img"
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]

        let nowDate = Date()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy/MM/dd_HH:mm:ss"
        let convertedDate = dateFormat.string(from: nowDate)
        guard let imageData = image.jpegData(compressionQuality: 0.7) ?? image.pngData() else { return }
        let url = URL(string: stringURL)!
        
        var request = URLRequest(url: url)
        let boundary = "Boundary-\(UUID().uuidString)"
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
//        let bodyData = createBody(parameters: ["userId": "user1"],
//                                  boundary: boundary,
//                                  data: imageData!, 
//                                  mimeType: "image/png",
//                                  filename: "user1.png")
        // title 텍스트 필드 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
        body.append("user1\r\n".data(using: .utf8)!)

        // 이미지 데이터 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        request.httpBody = body
        
//        URLSession.shared.dataTaskPublisher(for: request)
//            .tryMap { output in
//                guard let httpResponse = output.response as? HTTPURLResponse,
//                      httpResponse.statusCode == 200 else {
//                    throw URLError(.badServerResponse)
//                }
//                return output.data
//            }
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                case .finished:
//                    print("업로드 성공")
//                case .failure(let error):
//                    print("업로드 실패: \(error)")
//                }
//            }, receiveValue: { [weak self] (data: Data) in
//                if let image = UIImage(data: data) {
//                    self?.imageView.image = image
//                }
//            })
//            .store(in: &subscriptions)
        
//        let dataTask = URLSession.shared.dataTaskPublisher(for: url)
//            .tryMap { element -> Data in
//                guard let httpResponse = element.response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                                    throw URLError(.badServerResponse)
//                                }
//                                return element.data
//            }
//            .map { UIImage(data: $0)}
//            .replaceError(with: nil)
//            .subscribe(on: DispatchQueue.global(qos: .background))
//            .receive(on: RunLoop.main)
//            .eraseToAnyPublisher()

        AF.upload(multipartFormData: { multipartFormData in
            guard let imageData = image.jpegData(compressionQuality: 0.5) ?? image.pngData(),
                  let url = URL(string: stringURL)
            else {
                print("이미지 또는 URL을 불러올 수 없습니다.")
                return
            }
            multipartFormData.append(Data("user1".utf8), withName: "title")
            multipartFormData.append(imageData,
                                     withName: "image",
                                     fileName: "user1_\(convertedDate).jpg",
                                     mimeType: "image/jpg")
        }, to: stringURL, method: .post, headers: header)
        .responseData{ response in
            switch response.result {
            case .success(let data):
                if let result = UIImage(data: data) {
//                    DispatchQueue.main.async{
                    self.imageView.image = result
//                    }
                }
                
            case .failure(let error):
                print("Error has occured: \(error)")
            }
        }

    }

}



/*
 https://velog.io/@sanghwi_back/Swift-동시성-프로그래밍-2-DispatchQueue
 https://velog.io/@yy0867/Custom-Camera-정리
 https://peppo.tistory.com/189 카메라 정리
 https://liveupdate.tistory.com/445 cvpixelbuffer 등 정리
*/

/*
 
 1. 버튼을 누르면 localhost:8000/yl/img로 이미지가 간다.
 1.1: response는 구현없음.
 1.2: img보낼 때 타이틀이 이상하게 서버에 저장됨. image 자체를 파일명으로 넣어줘서 그런것같음.
 1.3: 버튼이 아니라 비동기식이어야 함. 타이머처럼 해야함.
 1.4: django 지금 csrf_excemp로 되어잇음. HTTP연결 시 CSRF 토큰을 어떻게 처리해야 할까(v) or HTTPS연결 시 어떻게 처리해야할까.
 
 2. xcode에 있는 이미지가 아니라 photoOutput의 프레임을 뽑아서 서버에 보내야함.
 2.1: photoOutput이나 AVCapturePhotOcaptureDelegate나 photoOutputDelegate로 이미지를 뽑아내야함.

 */
