//
//  PopUpInformVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/23/24.
//

import UIKit
import Alamofire

class PopUpInformVC: UIViewController {
    var id : String?
    var password : String?
    var name : String?
    var option : String?
    var phoneNum : String?
    
    @IBAction func clickCancelBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    // 확인 버튼 클릭
    @IBAction func clickCheckBtn(_ sender: Any) {
        // 회원가입 시도
        // 회원정보 보내줌
        register()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // 회원가입 시도
    // 회원정보 보내줌
    func register() {
        // id!, password!, name!, option!, phoneNum! 으로 이용하심 됩니다
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = "http://yellowline-demo.duckdns.org/user/signup/"
        let tmpData : [String : String] = ["id": id!,
                                           "password": password!,
                                           "name": name!,
                                           "option": option!,
                                           "phoneNum": phoneNum!]
        
        AF.upload(multipartFormData: { multipartFormData in
            for (key, val) in tmpData {
                multipartFormData.append(val.data(using: .utf8)!, withName: key)
            }
        }, to: loginURL, method: .post, headers: header)
        .responseDecodable(of: RegisterResult.self){ response in
            DispatchQueue.main.async {
                print(response.result)
                switch response.result {
                case let .success(response):
                    let result = response
                    // error가 없으면
                    guard result.errors == nil else {
                        // 에러화면을 띄워주던지하는 handler 코드...
                        print("Error occured during register...")
                        print("error\n\(result.errors)")
                        
                        // 회원가입 성공시 성공 안내 화면으로 이동
                        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "RegisterCompletedVC") else {return}
                        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                        self.present(nextVC, animated: true)
                        return
                    }
                    
                    // 회원가입 성공시 성공 안내 화면으로 이동
                    guard let nextVC = self.storyboard?.instantiateViewController(identifier: "RegisterCompletedVC") else {return}
                    nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                    self.present(nextVC, animated: true)
                case let .failure(error):
                    print("\nfailure\n",error)
                    print("------")
                default:
                    break
                }
            }
        } //Alamofire request end...
        

    }
}

struct RegisterResult : Codable {
    let success: Bool?
    let message: String?
    let errors: Params?
}
struct Params : Codable {
    let id : [String]
}
