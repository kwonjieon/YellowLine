//
//  LoginVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/21/24.
//

import UIKit
import Alamofire

class LoginVC: UIViewController {
    static var protectorID = ""
    @IBOutlet weak var PWField: UITextField!
    @IBOutlet weak var IDField: UITextField!
    
    // 로그인 버튼 클릭
    @IBAction func clickLoginBtn(_ sender: Any) {
        // 버튼 누르면 키보드가 자동으로 내려감
        PWField.resignFirstResponder()
        
        if PWField.text != "" && IDField.text != "" {
            // 아이디, 비밀번호 서버로 전송
            login()
        }
        else {
            print("아이디 또는 비밀번호를 입력하세요")
        }
    }

    // 임시 물체탐지 버튼 클릭
    @IBAction func clickLoginBtnProtect(_ sender: Any) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "ViewController") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
    }
    
    @IBAction func clickRegisterBtn(_ sender: Any) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "RegisterVC") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PWField.delegate = self
        IDField.delegate = self
        
        setPWField()
        setIDField()
    }
    
    // 로그인 시도
    func login() {
//         IDField.text!   -> 아이디
//         PWField.text!   -> 비밀번호 입니다

        // id, pw 검증
        guard let tmpId = IDField.text, isValidId(id: tmpId) else { return }
        guard let tmpPw = PWField.text, isValidPassword(pwd: tmpPw) else { return }
        
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = Config.default.urls.login
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(tmpId.data(using:.utf8)!, withName: "id")
            multipartFormData.append(tmpPw.data(using:.utf8)!, withName: "password")
        }, to: loginURL, method: .post, headers: header)
        .responseDecodable(of: LoginResult.self){ response in
            //결과.
            DispatchQueue.main.async {
                switch response.result {
                case let .success(response):
                    let result = response
                    // error가 없으면
                    guard let resOption = result.option else {
                        return
                    }
                    let cType = resOption
                    switch cType{
                        
                    case "Protector":
                        // 관계추가시에 필요한 보호자 ID 기록
                        LoginVC.protectorID = self.IDField.text!
                        
                        // 로그인 성공시 메인 화면(보호자)으로 이동
                        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "ProtectorMainVC") else {return}
                        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                        self.present(nextVC, animated: true)
                        
                        break
                    case "Protected":
                        // 로그인 성공시 메인 화면(피보호자)으로 이동
                        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "MainScreenVC") else {return}
                        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                        self.present(nextVC, animated: true)
                    default:
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
    
    func setPWField() {
        PWField.placeholder = "비밀번호"
        PWField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        PWField.returnKeyType = .done
    }
    
    func setIDField() {
        IDField.placeholder = "아이디"
        IDField.clearButtonMode = .always
        IDField.returnKeyType = .done
    }
    
    
    // MARK: 로그인 검증
    
    // 아이디 형식 검사
    func isValidId(id: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: id)
    }
    
    // 비밀번호 형식 검사
    func isValidPassword(pwd: String) -> Bool {
        let passwordRegEx = "^[a-zA-Z0-9]{8,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordTest.evaluate(with: pwd)
    }

}

struct LoginResult :Codable {
    let option : String?
    let error : String?
}

extension LoginVC:UITextFieldDelegate {
    /*
    func addLeftPadding() {
           let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.frame.height))
           self.leftView = paddingView
           self.leftViewMode = ViewMode.always
       }
     */
    
    // 키보드 외 다른 영역 클릭 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // 키보드 리턴(확인) 입력 시 키보드 내리기
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        PWField.resignFirstResponder()
        IDField.resignFirstResponder()
        
        return true
    }
}
