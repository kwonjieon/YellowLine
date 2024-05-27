//
//  SelectDestinationVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/20/24.
//

import UIKit
import Alamofire
class SelectDestinationVC: UIViewController {
    
    // SearchDestinationViewController 의 결과 리스트에서 선택한 데이터 전달받음
    var destinationName : String?
    var destinationLati : String?
    var destinationLongi : String?
    
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var popUpView: UIView!
    
    @IBAction func clickCancelBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func clickStartBtn(_ sender: Any) {
        print("start")
        
        sendStartNavi()
        
        let nextVC = self.storyboard?.instantiateViewController(identifier: "MapViewController") as! MapViewController
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        // MapViewControllerVC로 목적지이름, 위도, 경도 데이터 넘겨줌
        nextVC.destinationName = destinationName!
        nextVC.destinationLati = destinationLati!
        nextVC.destinationLongi = destinationLongi!
        
        self.present(nextVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setPopUpView()
        setCancelBtn()
        setStartBtn()
    }
    
    // 피보호자가 네비게이션 이용 중이라는 상태를 서버에 업데이트
    func sendStartNavi() {
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = "http://43.202.136.75/user/startnavi/"
        
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
    
    // 수정필요
    /*
    func saveSearchHistory() {
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = "http://43.202.136.75/user/routeSearch/"
        
        guard let text = searchBar.text else {
            return
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(text.data(using:.utf8)!, withName: "arrival")
        }, to: loginURL, method: .post, headers: header)
        .responseDecodable(of: RouteSearchResult.self){ response in
            DispatchQueue.main.async {
                switch response.result {
                case let .success(response):
                    let result = response
                    // error가 없으면 통과
                    guard let resOption = result.success else {
                        return
                    }
                    let cType = resOption
                    switch cType{
                        
                    case true:
                        print("저장성공")
                        break
                    default:
                        print("저장실패")
                        break
                    }
                case let .failure(error):
                    print(error)
                    print("실패입니다.")
                    
                default:
                    print("something wrong...")
                    break
                }
            }
        } //Alamofire request end...
        
    }
    */
    func setPopUpView() {
        popUpView.frame = CGRect(x: 0, y: 0, width: 346, height: 191)
        popUpView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        popUpView.layer.cornerRadius = 20
        
        popUpView.translatesAutoresizingMaskIntoConstraints = false
        popUpView.widthAnchor.constraint(equalToConstant: 346).isActive = true
        popUpView.heightAnchor.constraint(equalToConstant: 191).isActive = true
        popUpView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 23).isActive = true
        popUpView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 300).isActive = true
        
    }
    
    func setCancelBtn() {
        cancelBtn.frame = CGRect(x: 0, y: 0, width: 150, height: 44)
        cancelBtn.layer.backgroundColor = UIColor(red: 0.797, green: 0.797, blue: 0.797, alpha: 1).cgColor
        cancelBtn.layer.cornerRadius = 15

        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.widthAnchor.constraint(equalToConstant: 150).isActive = true
        cancelBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        cancelBtn.leadingAnchor.constraint(equalTo: popUpView.leadingAnchor, constant: 17).isActive = true
        cancelBtn.topAnchor.constraint(equalTo: popUpView.topAnchor, constant: 130).isActive = true
        cancelBtn.titleLabel!.text = "취소"
        cancelBtn.tintColor = UIColor(red: 0.365, green: 0.365, blue: 0.365, alpha: 1)
    }
    
    func setStartBtn() {
        startBtn.frame = CGRect(x: 0, y: 0, width: 150, height: 44)
        startBtn.layer.backgroundColor = UIColor(red: 1, green: 0.842, blue: 0.437, alpha: 1).cgColor
        startBtn.layer.cornerRadius = 15

        startBtn.translatesAutoresizingMaskIntoConstraints = false
        startBtn.widthAnchor.constraint(equalToConstant: 150).isActive = true
        startBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        startBtn.leadingAnchor.constraint(equalTo: popUpView.leadingAnchor, constant: 179).isActive = true
        startBtn.topAnchor.constraint(equalTo: popUpView.topAnchor, constant: 130).isActive = true
        startBtn.titleLabel!.text = "안내 시작"
        startBtn.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
}
