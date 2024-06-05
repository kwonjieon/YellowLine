//
//  MainScreenVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/15/24.
//

import UIKit
import Alamofire
class MainScreenVC: UIViewController {
    var userID: String?
    
    @IBOutlet weak var naviView: UIView!
    @IBOutlet weak var objectView: UIView!
    
    @IBOutlet weak var naviTitleLabel: UILabel!
    @IBOutlet weak var naviDescLabel: UILabel!
    
    @IBOutlet weak var objectTitleLabel: UILabel!
    @IBOutlet weak var objectDescLabel: UILabel!
    
    @IBOutlet weak var title1: UILabel!
    @IBOutlet weak var title2: UILabel!
    @IBOutlet weak var designView: UIView!
    

    @IBOutlet weak var logoutBtn: UIButton!
    @IBAction func clickLogoutBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBOutlet weak var naviIcon: UIImageView!
    @IBOutlet weak var objectIcon: UIImageView!
    
    // 네비게이션 버튼 클릭 시 실행되는 함수
    @objc func clickNaviBtn(_ gesture: UITapGestureRecognizer) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "SearchDestinationViewController") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
    }
    
    // 객체탐지 버튼 클릭 시 실행되는 함수
    @objc func clickobjectDetectBtn(_ gesture: UITapGestureRecognizer) {
        sendStartWalk()
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "ObjectDetectionVC") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
    }
    
    // 피보호자가 물체탐지 이용 중이라는 상태를 서버에 업데이트
    func sendStartWalk() {
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = "http://43.202.136.75/user/startwalk/"
        
        AF.request(loginURL,
                   method: .post,
                   encoding: JSONEncoding(options: []),
                   headers: ["Content-Type":"application/json", "Accept":"application/json"])
            .responseJSON { response in
            /** 서버로부터 받은 데이터 활용 */
            switch response.result {
            case .success(let data):
                break
            case .failure(let error):
                break
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        setNaviView()
        setObjectView()
        setTitle1()
        setTitle2()
        design()
        setIcon()
        setLogout()
    }
    
    func setNaviView() {
        naviView.frame = CGRect(x: 0, y: 0, width: 356, height: 134)
        naviView.layer.backgroundColor = UIColor(red: 1, green: 0.841, blue: 0.468, alpha: 1).cgColor
        naviView.layer.cornerRadius = 20

        naviView.translatesAutoresizingMaskIntoConstraints = false
        naviView.widthAnchor.constraint(equalToConstant: 356).isActive = true
        naviView.heightAnchor.constraint(equalToConstant: 134).isActive = true
        naviView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 18).isActive = true
        naviView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 504).isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clickNaviBtn(_:)))
        naviView.addGestureRecognizer(tapGesture)
        naviView.isUserInteractionEnabled = true
        
        naviTitleLabel.text = "길찾기"
        naviTitleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        naviTitleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 21)
        naviTitleLabel.textAlignment = .center

        naviTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        naviTitleLabel.leadingAnchor.constraint(equalTo: naviView.leadingAnchor, constant: 106).isActive = true
        naviTitleLabel.topAnchor.constraint(equalTo: naviView.topAnchor, constant: 41).isActive = true
        
        naviDescLabel.text = "길 안내 및 위험한 물체 확인 서비스"
        naviDescLabel.textColor = UIColor(red: 0.21, green: 0.21, blue: 0.21, alpha: 1)
        naviDescLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 17)
        naviDescLabel.textAlignment = .center

        naviDescLabel.translatesAutoresizingMaskIntoConstraints = false
        naviDescLabel.leadingAnchor.constraint(equalTo: naviView.leadingAnchor, constant: 106).isActive = true
        naviDescLabel.topAnchor.constraint(equalTo: naviView.topAnchor, constant: 70).isActive = true
    }
    
    func setObjectView() {
        objectView.frame = CGRect(x: 0, y: 0, width: 356, height: 134)
        objectView.layer.backgroundColor = UIColor(red: 1, green: 0.841, blue: 0.468, alpha: 1).cgColor
        objectView.layer.cornerRadius = 20

        objectView.translatesAutoresizingMaskIntoConstraints = false
        objectView.widthAnchor.constraint(equalToConstant: 356).isActive = true
        objectView.heightAnchor.constraint(equalToConstant: 134).isActive = true
        objectView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 18).isActive = true
        objectView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 658).isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clickobjectDetectBtn(_:)))
        objectView.addGestureRecognizer(tapGesture)
        objectView.isUserInteractionEnabled = true
        
        
        objectTitleLabel.text = "안전보행"
        objectTitleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        objectTitleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 21)
        objectTitleLabel.textAlignment = .center

        objectTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        objectTitleLabel.leadingAnchor.constraint(equalTo: objectView.leadingAnchor, constant: 106).isActive = true
        objectTitleLabel.topAnchor.constraint(equalTo: objectView.topAnchor, constant: 41).isActive = true
        
        objectDescLabel.text = "보행 중 위험한 물체 확인 서비스"
        objectDescLabel.textColor = UIColor(red: 0.21, green: 0.21, blue: 0.21, alpha: 1)
        objectDescLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 17)
        objectDescLabel.textAlignment = .center

        objectDescLabel.translatesAutoresizingMaskIntoConstraints = false
        objectDescLabel.leadingAnchor.constraint(equalTo: objectView.leadingAnchor, constant: 106).isActive = true
        objectDescLabel.topAnchor.constraint(equalTo: objectView.topAnchor, constant: 66).isActive = true
    }
    
    func setTitle1() {
        title1.text = "Yellow"
        title1.textColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1)
        title1.font = UIFont(name: "AppleSDGothicNeoH00", size: 80)
        title1.textAlignment = .center

        title1.translatesAutoresizingMaskIntoConstraints = false
        title1.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
        title1.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 159).isActive = true
    }
    
    func setTitle2() {
        title2.text = "Line"
        title2.textColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1)
        title2.font = UIFont(name: "AppleSDGothicNeoH00", size: 80)
        title2.textAlignment = .center

        title2.translatesAutoresizingMaskIntoConstraints = false
        title2.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
        title2.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 223).isActive = true
    }
    
    func design() {
        designView.frame = CGRect(x: 0, y: 0, width: 172, height: 39)
        designView.layer.backgroundColor = UIColor(red: 1, green: 0.841, blue: 0.468, alpha: 1).cgColor

        designView.translatesAutoresizingMaskIntoConstraints = false
        designView.widthAnchor.constraint(equalToConstant: 172).isActive = true
        designView.heightAnchor.constraint(equalToConstant: 39).isActive = true
        designView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 32).isActive = true
        designView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 240).isActive = true
    }
    
    func setIcon() {
        naviIcon.frame = CGRect(x: 0, y: 0, width: 84, height: 84)
        naviIcon.translatesAutoresizingMaskIntoConstraints = false
        naviIcon.widthAnchor.constraint(equalToConstant: 84).isActive = true
        naviIcon.heightAnchor.constraint(equalToConstant: 84).isActive = true
        naviIcon.leadingAnchor.constraint(equalTo: naviView.leadingAnchor, constant: 12).isActive = true
        naviIcon.topAnchor.constraint(equalTo: naviView.topAnchor, constant: 25).isActive = true
        
        objectIcon.frame = CGRect(x: 0, y: 0, width: 84, height: 84)
        objectIcon.translatesAutoresizingMaskIntoConstraints = false
        objectIcon.widthAnchor.constraint(equalToConstant: 84).isActive = true
        objectIcon.heightAnchor.constraint(equalToConstant: 84).isActive = true
        objectIcon.leadingAnchor.constraint(equalTo: objectView.leadingAnchor, constant: 12).isActive = true
        objectIcon.topAnchor.constraint(equalTo: objectView.topAnchor, constant: 25).isActive = true
    }
    
    func setLogout() {
        logoutBtn.frame = CGRect(x: 0, y: 0, width: 82, height: 31)
        logoutBtn.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        logoutBtn.layer.cornerRadius = 10

        logoutBtn.translatesAutoresizingMaskIntoConstraints = false
        logoutBtn.widthAnchor.constraint(equalToConstant: 82).isActive = true
        logoutBtn.heightAnchor.constraint(equalToConstant: 31).isActive = true
        logoutBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 292).isActive = true
        logoutBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 59).isActive = true
        logoutBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
}
