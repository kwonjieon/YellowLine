//
//  ViewController.swift
//  videoTest
//
//  Created by 정성희 on 3/25/24.
//

import AVKit
import UIKit


/**
 
 메인 뷰에서 카메라캡처를 위해 필요한 준비물
 1. 맨 앞단에서 카메라 큐를 관리할 queue
 2. 카메라세션 초기화 및 세션 시작, 종료 코드 추가
 3. 카메라 세션 초기화 후 권한 추가 코드.
 */
class ViewController: UIViewController{
    
    @IBOutlet weak var previewView: UIView!
     @IBOutlet var imageView: UIImageView!

    @IBOutlet var btns: UIButton!
    
    let queue = DispatchQueue(label: "videoQueue")
    
    
    var cameraSession: CameraSession?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        cameraSession = CameraSession(queue: self.queue, view: self.imageView)
        cameraSession?.checkCameraAuthor()
        self.cameraSession?.startSession()
    }
    
    @IBAction func btnclick(_ sender: Any) {
        guard let image = UIImage(named: "bus.jpg"),
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        cameraSession?.socketManager?.send(image: imageData)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraSession?.stopSession()
        
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
