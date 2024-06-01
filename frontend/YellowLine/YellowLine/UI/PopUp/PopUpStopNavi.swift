//
//  PopUpStopNavi.swift
//  YellowLine
//
//  Created by 정성희 on 5/29/24.
//

import UIKit

class PopUpStopNavi: UIViewController {

    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    var titletext : String?
    var descriptionText : String?
    var btn1Text : String?
    var btn2Text : String?
    var function : String?
    
    var webRTCManager : WebRTCManager?
    
    @IBAction func clickCancelBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func clickStopBtn(_ sender: Any) {
        mapViewController.sendChangeToOffline()
        mapViewController.locationManager.stopUpdatingLocation()
        if let presentingVC = self.presentingViewController?.presentingViewController?.presentingViewController?.presentingViewController {
            webRTCManager!.disconnect()
            webRTCManager = nil
            // 메인화면으로 돌아감
            presentingVC.dismiss(animated: true, completion: nil)
        }
    }
    
    var mapViewController = MapViewController()
    
    deinit {
        print("****PopUpStopNavi deinit...")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBasicInfo()
        setLabel()
        setPopUpView()
        setCancelBtn()
        setStartBtn()
    }
    
    func setBasicInfo() {
        titleLabel.text = titletext
        descriptionLabel.text = descriptionText
        cancelBtn.setTitle(btn1Text, for: .normal)
        stopBtn.setTitle(btn2Text, for: .normal)
    }
    
    func setLabel() {
        // 제목
        titleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 22)
        titleLabel.textAlignment = .center
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: popUpView.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: popUpView.topAnchor, constant: 39).isActive = true
        
        // 부가 설명
        descriptionLabel.textColor = UIColor(red: 0.539, green: 0.539, blue: 0.539, alpha: 1)
        descriptionLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 18)
        descriptionLabel.textAlignment = .center
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.centerXAnchor.constraint(equalTo: popUpView.centerXAnchor).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: popUpView.topAnchor, constant: 83).isActive = true
        
    }
    
    func setPopUpView() {
        popUpView.frame = CGRect(x: 0, y: 0, width: 350, height: 205)
        popUpView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        popUpView.layer.cornerRadius = 20
        
        popUpView.translatesAutoresizingMaskIntoConstraints = false
        popUpView.widthAnchor.constraint(equalToConstant: 350).isActive = true
        popUpView.heightAnchor.constraint(equalToConstant: 205).isActive = true
        popUpView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 21).isActive = true
        popUpView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 320).isActive = true
        
    }
    
    func setCancelBtn() {
        cancelBtn.frame = CGRect(x: 0, y: 0, width: 142, height: 44)
        cancelBtn.layer.backgroundColor = UIColor(red: 0.857, green: 0.855, blue: 0.89, alpha: 1).cgColor
        cancelBtn.layer.cornerRadius = 10

        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.widthAnchor.constraint(equalToConstant: 142).isActive = true
        cancelBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        cancelBtn.leadingAnchor.constraint(equalTo: popUpView.leadingAnchor, constant: 25).isActive = true
        cancelBtn.topAnchor.constraint(equalTo: popUpView.topAnchor, constant: 136).isActive = true
        
        cancelBtn.titleLabel!.text = "취소"
        cancelBtn.tintColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
    }
    
    func setStartBtn() {
        stopBtn.frame = CGRect(x: 0, y: 0, width: 142, height: 44)
        stopBtn.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        stopBtn.layer.cornerRadius = 10

        stopBtn.translatesAutoresizingMaskIntoConstraints = false
        stopBtn.widthAnchor.constraint(equalToConstant: 142).isActive = true
        stopBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stopBtn.leadingAnchor.constraint(equalTo: popUpView.leadingAnchor, constant: 183).isActive = true
        stopBtn.topAnchor.constraint(equalTo: popUpView.topAnchor, constant: 136).isActive = true
        stopBtn.titleLabel!.text = "안내 중단"
        stopBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }

}
