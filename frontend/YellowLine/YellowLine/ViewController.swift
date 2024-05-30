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
    @IBOutlet var callBtn: UIButton!
    var webRTCManager: WebRTCManager?
    var cameraSession: CameraSession?
    
    @IBOutlet var midasView: UIImageView!
    
    @IBOutlet var localView: UIView!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        webRTCManager = WebRTCManager(uiView: localView,"YLUSER01")
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraSession?.stopSession()
        
    }
    
    @IBAction func moveToSearch(_ sender: Any) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "MainScreenVC") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
          self.present(nextVC, animated: true)
    }
    @IBAction func callBtnTapped(_ sender: Any) {
//        self.webRTCManager?.callButtonTapped()
    }
}
