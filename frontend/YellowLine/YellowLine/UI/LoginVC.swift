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
    
    @IBOutlet weak var title1: UILabel!
    @IBOutlet weak var title2: UILabel!
    
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var loginBtn: UIButton!
    
    @IBOutlet weak var designView: UIView!
    
    
    
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
        setBtn()
        setLabel()
        setDesignView()
    }
    
    // 로그인 시도
    func login() {
//         IDField.text!   -> 아이디
//         PWField.text!   -> 비밀번호 입니다

        // id, pw 검증
        //guard let tmpId = IDField.text, isValidId(id: tmpId) else { return }
        //guard let tmpPw = PWField.text, isValidPassword(pwd: tmpPw) else { return }
        
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = Config.urls.login
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(self.IDField.text!.data(using:.utf8)!, withName: "id")
            multipartFormData.append(self.PWField.text!.data(using:.utf8)!, withName: "password")
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
                        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "MainScreenVC") as? MainScreenVC else {return}
                        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
//                        nextVC.userID = self.IDField.text!
                        UserDefaults.standard.setValue(self.IDField.text!, forKey: "uid")
                        
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
        PWField.isSecureTextEntry = true
        
        PWField.frame = CGRect(x: 0, y: 0, width: 299, height: 50)
        PWField.backgroundColor = UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1)
        
        PWField.translatesAutoresizingMaskIntoConstraints = false
        PWField.widthAnchor.constraint(equalToConstant: 299).isActive = true
        PWField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        PWField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 47).isActive = true
        PWField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 396).isActive = true
        
    }
    
    func setIDField() {
        IDField.placeholder = "아이디"
        IDField.clearButtonMode = .always
        IDField.returnKeyType = .done

        IDField.frame = CGRect(x: 0, y: 0, width: 299, height: 50)
        IDField.backgroundColor = UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1)
        IDField.layer.cornerRadius = 10
        
        IDField.translatesAutoresizingMaskIntoConstraints = false
        IDField.widthAnchor.constraint(equalToConstant: 299).isActive = true
        IDField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        IDField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 47).isActive = true
        IDField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 335).isActive = true
    }
    
    func setBtn() {
        loginBtn.frame = CGRect(x: 0, y: 0, width: 299, height: 50)
        loginBtn.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        loginBtn.layer.cornerRadius = 10
        loginBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        loginBtn.translatesAutoresizingMaskIntoConstraints = false
        loginBtn.widthAnchor.constraint(equalToConstant: 299).isActive = true
        loginBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        loginBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 47).isActive = true
        loginBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 484).isActive = true
        

        registerBtn.tintColor = UIColor(red: 0.539, green: 0.539, blue: 0.539, alpha: 1)
        registerBtn.translatesAutoresizingMaskIntoConstraints = false
        //registerBtn.widthAnchor.constraint(equalToConstant: 74).isActive = true
        //registerBtn.heightAnchor.constraint(equalToConstant: 25).isActive = true
        registerBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 159).isActive = true
        registerBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 545).isActive = true
    }
    
    func setLabel() {
        title1.textColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1)
        title1.font = UIFont(name: "AppleSDGothicNeoH00", size: 60)
        title1.textAlignment = .center
        title1.translatesAutoresizingMaskIntoConstraints = false
        title1.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 47).isActive = true
        title1.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 182).isActive = true
        
        title2.textColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1)
        title2.font = UIFont(name: "AppleSDGothicNeoH00", size: 60)
        title2.textAlignment = .center
        title2.translatesAutoresizingMaskIntoConstraints = false
        title2.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 49).isActive = true
        title2.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 233).isActive = true
    }
    
    func setDesignView() {
        designView.frame = CGRect(x: 0, y: 0, width: 152, height: 28)
        designView.layer.backgroundColor = UIColor(red: 1, green: 0.841, blue: 0.468, alpha: 1).cgColor

        designView.translatesAutoresizingMaskIntoConstraints = false
        designView.widthAnchor.constraint(equalToConstant: 152).isActive = true
        designView.heightAnchor.constraint(equalToConstant: 28).isActive = true
        designView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 47).isActive = true
        designView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 275).isActive = true
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
