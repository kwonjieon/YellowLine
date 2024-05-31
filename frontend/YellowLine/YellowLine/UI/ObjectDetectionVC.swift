//
//  ObjectDetectionVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/30/24.
//

import UIKit

class ObjectDetectionVC: UIViewController {
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    // 물체탐지 레이어
    @IBOutlet var localView: UIView!
    var webRTCManager: WebRTCManager?
    var cameraSession: CameraSession?
    
    // 피보호자 아이디
    var protectedId = "YLUSER01"
    @IBAction func clickBackBtn(_ sender: Any) {
        self.dismiss(animated: true)
        self.webRTCManager!.webRTCClient.disconnect()
        self.cameraSession?.stopSession()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        webRTCManager = WebRTCManager(uiView: localView, protectedId)
        
        setLabel()
        setBtn()
    }
    
    func setBtn() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 33).isActive = true
        backBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 70).isActive = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraSession?.stopSession()
    }
    
    func setNavigationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 120)
        navigationBar.layer.backgroundColor = UIColor(red: 1, green: 0.841, blue: 0.468, alpha: 1).cgColor

        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }
    
    func setLabel() {
        titleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        titleLabel.textAlignment = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 75).isActive = true
    }

}
