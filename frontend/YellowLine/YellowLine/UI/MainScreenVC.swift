//
//  MainScreenVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/15/24.
//

import UIKit
import Alamofire
class MainScreenVC: UIViewController {
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
    
    lazy var naviBtn: UIView = {
        let view = UIView()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clickNaviBtn(_:)))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        view.frame = CGRect(x: 0, y: 0, width: 356, height: 149)
        
        var shadows = UIView()
        shadows.frame = view.frame
        shadows.clipsToBounds = false
        view.addSubview(shadows)

        let shadowPath0 = UIBezierPath(roundedRect: shadows.bounds, cornerRadius: 20)
        let layer0 = CALayer()
        layer0.shadowPath = shadowPath0.cgPath
        layer0.shadowColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.25).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 25
        layer0.shadowOffset = CGSize(width: 0, height: 0)
        layer0.bounds = shadows.bounds
        layer0.position = shadows.center
        shadows.layer.addSublayer(layer0)

        var shapes = UIView()
        shapes.frame = view.frame
        shapes.clipsToBounds = true
        view.addSubview(shapes)

        let layer1 = CALayer()
        layer1.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        layer1.bounds = shapes.bounds
        layer1.position = shapes.center
        shapes.layer.addSublayer(layer1)

        shapes.layer.cornerRadius = 20
        
        let title = UILabel()
        title.frame = CGRect(x: 0, y: 0, width: 63, height: 22)
        title.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        title.font = UIFont(name: "AppleSDGothicNeoB00-Regular", size: 24)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.66

        title.textAlignment = .center
        title.attributedText = NSMutableAttributedString(string: "길찾기", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        view.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.widthAnchor.constraint(equalToConstant: 63).isActive = true
        title.heightAnchor.constraint(equalToConstant: 22).isActive = true
        title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 152).isActive = true
        title.topAnchor.constraint(equalTo: view.topAnchor, constant: 28).isActive = true

        
        let description = UILabel()
        description.frame = CGRect(x: 0, y: 0, width: 284, height: 46)
        description.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        description.font = UIFont(name: "AppleSDGothicNeoL00-Regular", size: 18)
        description.numberOfLines = 0
        description.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0.96

        description.textAlignment = .center
        description.attributedText = NSMutableAttributedString(string: "보행시 위험한 물체가 있는지 확인하면서\n음성 안내와 함께 길을 안내해드려요.", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        view.addSubview(description)
        description.translatesAutoresizingMaskIntoConstraints = false
        description.widthAnchor.constraint(equalToConstant: 284).isActive = true
        description.heightAnchor.constraint(equalToConstant: 46).isActive = true
        description.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35).isActive = true
        description.topAnchor.constraint(equalTo: view.topAnchor, constant: 68).isActive = true
    
        return view
    }()
    
    lazy var objectDetectBtn: UIView = {
        let view = UIView()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clickobjectDetectBtn(_:)))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        
        view.frame = CGRect(x: 0, y: 0, width: 356, height: 149)
        var shadows = UIView()
        shadows.frame = view.frame
        shadows.clipsToBounds = false
        view.addSubview(shadows)

        let shadowPath0 = UIBezierPath(roundedRect: shadows.bounds, cornerRadius: 20)
        let layer0 = CALayer()
        layer0.shadowPath = shadowPath0.cgPath
        layer0.shadowColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.25).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 25
        layer0.shadowOffset = CGSize(width: 0, height: 0)
        layer0.bounds = shadows.bounds
        layer0.position = shadows.center
        shadows.layer.addSublayer(layer0)

        var shapes = UIView()
        shapes.frame = view.frame
        shapes.clipsToBounds = true
        view.addSubview(shapes)

        let layer1 = CALayer()
        layer1.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        layer1.bounds = shapes.bounds
        layer1.position = shapes.center
        shapes.layer.addSublayer(layer1)

        shapes.layer.cornerRadius = 20

        
        var title = UILabel()
        title.frame = CGRect(x: 0, y: 0, width: 158, height: 22)
        title.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        title.font = UIFont(name: "AppleSDGothicNeoB00-Regular", size: 24)
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.66

        title.textAlignment = .center
        title.attributedText = NSMutableAttributedString(string: "위험한 물체 탐색", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        view.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.widthAnchor.constraint(equalToConstant: 158).isActive = true
        title.heightAnchor.constraint(equalToConstant: 22).isActive = true
        title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 99).isActive = true
        title.topAnchor.constraint(equalTo: view.topAnchor, constant: 28).isActive = true
        
        var description = UILabel()
        description.frame = CGRect(x: 0, y: 0, width: 202, height: 46)
        description.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        description.font = UIFont(name: "AppleSDGothicNeoL00-Regular", size: 18)
        description.numberOfLines = 0
        description.lineBreakMode = .byWordWrapping
        
        paragraphStyle.lineHeightMultiple = 0.96
        // Line height: 22 pt
        
        description.textAlignment = .center
        description.attributedText = NSMutableAttributedString(string: "보행시 위험한 물체가 있는지\n확인해 드려요.", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        view.addSubview(description)
        description.translatesAutoresizingMaskIntoConstraints = false
        description.widthAnchor.constraint(equalToConstant: 202).isActive = true
        description.heightAnchor.constraint(equalToConstant: 46).isActive = true
        description.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 75).isActive = true
        description.topAnchor.constraint(equalTo: view.topAnchor, constant: 68).isActive = true
        
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        var view = UILabel()
        view.frame = CGRect(x: 0, y: 0, width: 172, height: 22)
        view.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        view.font = UIFont(name: "AppleSDGothicNeoH00", size: 32)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1
        // Line height: 22 pt
        // (identical to box height)
        view.textAlignment = .center
        view.attributedText = NSMutableAttributedString(string: "Yellow Line", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.00)
        
        // 길찾기 버튼 위치세팅
        self.view.addSubview(naviBtn)

        naviBtn.translatesAutoresizingMaskIntoConstraints = false
        naviBtn.widthAnchor.constraint(equalToConstant: 356).isActive = true
        naviBtn.heightAnchor.constraint(equalToConstant: 149).isActive = true
        
        naviBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 19).isActive = true
        naviBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 483).isActive = true
        
        // 위험한 물체 탐색 버튼 위치세팅
        self.view.addSubview(objectDetectBtn)

        objectDetectBtn.translatesAutoresizingMaskIntoConstraints = false
        objectDetectBtn.widthAnchor.constraint(equalToConstant: 356).isActive = true
        objectDetectBtn.heightAnchor.constraint(equalToConstant: 149).isActive = true
        
        objectDetectBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 19).isActive = true
        objectDetectBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 653).isActive = true
        
        // 타이틀
        self.view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.widthAnchor.constraint(equalToConstant: 172).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 110).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 213).isActive = true
    }
}
