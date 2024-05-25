//
//  LoginVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/21/24.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet weak var PWField: UITextField!
    @IBOutlet weak var IDField: UITextField!
    
    // 피보호자 로그인 버튼 클릭
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

    @IBAction func clickLoginBtnProtect(_ sender: Any) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "ProtectorMainVC") else {return}
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
        // IDField.text!   -> 아이디
        // PWField.text!   -> 비밀번호 입니다
        
        // 로그인 성공시 메인 화면(피보호자)으로 이동
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "MainScreenVC") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
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

}

extension LoginVC:UITextFieldDelegate {
    /*
    func addLeftPadding() {
           let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.frame.height))
           self.leftView = paddingView
           self.leftViewMode = ViewMode.always
       }
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        PWField.resignFirstResponder()
        IDField.resignFirstResponder()
        
        return true
    }
}
