//
//  ViewController.swift
//  videoTest
//
//  Created by 정성희 on 3/25/24.
//

import UIKit
import AVFoundation
import Alamofire

class ViewController: UIViewController {
    
    @IBOutlet var sendBtn: UIButton!
    @IBOutlet weak var previewView: UIView!
    
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInTripleCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .back)

        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
//        guard let captureDevice = discoverySession.devices.first else {
//            return
//        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: captureDevice)
//            let cameraInput = try AVCaptureDeviceInput(device: captureDevice)

            photoOutput = AVCapturePhotoOutput()
//            self.setupPhotoOutput()
            
            captureSession.sessionPreset = .photo
            if captureSession.canAddInput(cameraInput) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(cameraInput)
                captureSession.addOutput(photoOutput)
                captureSession.commitConfiguration()
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            self.previewView.layer.addSublayer(videoPreviewLayer)
            
            // .userInitiated or .userInteractive = UI 업데이트 시
            DispatchQueue.global(qos: .userInitiated).async {
                
                self.captureSession.startRunning()
                // qos : .utility = 이미지 전송,수송 시 사용. 꽤 긴 처리시간을 갖을 때 사용한다.
                DispatchQueue.main.async {
                    self.videoPreviewLayer.frame = self.previewView.bounds
                }
            }

            
        } catch {
            print(error)
        }
      
    }
    

    
    //MARK: 사진 아웃풋 설정
    func setupPhotoOutput() {
        photoOutput = AVCapturePhotoOutput()
        photoOutput.isResponsiveCaptureEnabled = true
        photoOutput.connections.first?.videoRotationAngle =  90
    }
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    

    @IBAction func postImg(_ sender: Any) {
        upload()
//        print("Hello")
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

    func upload() {
        print("Upload is approaching...")

        
        let stringURL = "https://4049-116-32-21-139.ngrok-free.app/yl/img"
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
//        guard let image = UIImage(named: "chauchaudog.jpg"),
//              let imageData = image.jpegData(compressionQuality: 1) ?? image.pngData(),
//              let url = URL(string: stringURL)
//        else {
//            print("이미지 또는 URL을 불러올 수 없습니다.")
//            return
//        }
        
        AF.upload(multipartFormData: { multipartFormData in
            guard let image = UIImage(named: "chauchaudog.jpg"),
                  let imageData = image.jpegData(compressionQuality: 1) ?? image.pngData(),
                  let url = URL(string: stringURL)
            else {
                print("이미지 또는 URL을 불러올 수 없습니다.")
                return
            }
            multipartFormData.append(Data("user1".utf8), withName: "title")
            multipartFormData.append(imageData,
                                     withName: "image",
                                     fileName: "chauchaudog.jpg",
                                     mimeType: "image/jpg")
        }, to: stringURL, method: .post, headers: header)
        .response{ response in
            guard let statusCode = response.response?.statusCode else {return }
                    switch statusCode{
                    case 200: print("이미지 전송 완료")
                    default:
                        print("오류발생")
                    }
        }


    }

}



/*
 https://velog.io/@sanghwi_back/Swift-동시성-프로그래밍-2-DispatchQueue
 https://velog.io/@yy0867/Custom-Camera-정리

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
