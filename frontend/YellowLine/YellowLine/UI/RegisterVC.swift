//
//  RegisterVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/23/24.
//

import UIKit

class RegisterVC: UIViewController {

    @IBOutlet var optionBtn: [UIButton]!
    var option : String?
    
    @IBOutlet weak var IDField: UITextField!
    @IBOutlet weak var PWField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var telnumField: UITextField!
    
    @IBOutlet weak var registerBtn: UIButton!
    
    // 회원가입 버튼 클릭
    @IBAction func clickRegisterBtn(_ sender: Any) {
        // 값을 모두 입력해야함
        if IDField.text != ""
            && PWField.text != ""
            && nameField.text != ""
            && telnumField.text != ""
            && option != nil {
            let nextVC = self.storyboard?.instantiateViewController(identifier: "PopUpInformVC") as! PopUpInformVC
            nextVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            
            // 가입정보 데이터 넘겨줌
            nextVC.id = IDField.text!
            nextVC.password = PWField.text!
            nextVC.name = nameField.text!
            nextVC.option = self.option!
            nextVC.phoneNum = telnumField.text!
            
            self.present(nextVC, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IDField.delegate = self
        PWField.delegate = self
        nameField.delegate = self
        telnumField.delegate = self
        
        self.optionBtn.forEach{
            $0.addTarget(self, action: #selector(self.radioOptionBtn(_ :)), for: .touchUpInside)
        }
        
        setIDField()
        setPWField()
        setNameField()
        setPhoneField()
    }

    func setIDField() {
        IDField.placeholder = "아이디"
        IDField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        IDField.returnKeyType = .done
    }
    
    func setPWField() {
        PWField.placeholder = "비밀번호"
        PWField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        PWField.returnKeyType = .done
    }
    
    func setNameField() {
        nameField.placeholder = "이름"
        nameField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        nameField.returnKeyType = .done
    }
    
    func setPhoneField() {
        telnumField.placeholder = "전화번호"
        telnumField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        telnumField.returnKeyType = .done
    }
    
    @objc func radioOptionBtn(_ sender: UIButton) {
        print("번호 : \(sender.tag)")
        
        self.optionBtn.forEach {
            // sender로 들어온 버튼과 tag를 비교
            if $0.tag == sender.tag {
                // 보호자 클릭한 경우
                if $0.tag == 0 {
                    option = "Protector"
                }
                // 피보호자 클릭한 경우
                else {
                    option = "Protected"
                }
                
                $0.tintColor = .blue
            } else {
                // 다른 tag이면 색이 없는 동그라미로 변경
                $0.tintColor = .yellow
            }
        }
    }
}

extension RegisterVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        PWField.resignFirstResponder()
        IDField.resignFirstResponder()
        nameField.resignFirstResponder()
        telnumField.resignFirstResponder()
        
        return true
    }
}
