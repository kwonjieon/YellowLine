//
//  RegisterVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/23/24.
//

import UIKit

class RegisterVC: UIViewController {
    @IBAction func clickBackBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBOutlet var optionBtn: [UIButton]!
    var option : String?
    @IBOutlet weak var IDField: UITextField!
    @IBOutlet weak var PWField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var telnumField: UITextField!
    @IBOutlet weak var registerBtn: UIButton!
    
    @IBOutlet weak var idLable: UILabel!
    @IBOutlet weak var pwLable: UILabel!
    @IBOutlet weak var nameLable: UILabel!
    @IBOutlet weak var phoneNumLable: UILabel!
    @IBOutlet weak var selectLable: UILabel!
    
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var titleLable: UILabel!
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
        setRegisterBtn()
        setOptBtns()
        setLable()
        setNavivgationBar()
    }

    func setIDField() {
        IDField.placeholder = "아이디"
        IDField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        IDField.returnKeyType = .done

        IDField.frame = CGRect(x: 0, y: 0, width: 333, height: 50)
        IDField.backgroundColor = UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1)
        IDField.layer.cornerRadius = 10

        var parent = self.view!
        
        IDField.translatesAutoresizingMaskIntoConstraints = false
        IDField.widthAnchor.constraint(equalToConstant: 333).isActive = true
        IDField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        IDField.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 30).isActive = true
        IDField.topAnchor.constraint(equalTo: parent.topAnchor, constant: 171).isActive = true
    }
    
    func setPWField() {
        PWField.placeholder = "비밀번호"
        PWField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        PWField.returnKeyType = .done
        PWField.isSecureTextEntry = true

        PWField.frame = CGRect(x: 0, y: 0, width: 333, height: 50)
        PWField.backgroundColor = UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1)
        PWField.layer.cornerRadius = 10

        PWField.translatesAutoresizingMaskIntoConstraints = false
        PWField.widthAnchor.constraint(equalToConstant: 333).isActive = true
        PWField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        PWField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
        PWField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 263).isActive = true
    }
    
    func setNameField() {
        nameField.placeholder = "이름"
        nameField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        nameField.returnKeyType = .done
        
        nameField.frame = CGRect(x: 0, y: 0, width: 333, height: 50)
        nameField.backgroundColor = UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1)
        nameField.layer.cornerRadius = 10

        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.widthAnchor.constraint(equalToConstant: 333).isActive = true
        nameField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        nameField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
        nameField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 354).isActive = true
    }
    
    func setPhoneField() {
        telnumField.placeholder = "전화번호"
        telnumField.clearButtonMode = .always
        // 키보드 입력시 엔터키 표출
        telnumField.returnKeyType = .done
        
        telnumField.frame = CGRect(x: 0, y: 0, width: 333, height: 50)
        telnumField.backgroundColor = UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1)
        telnumField.layer.cornerRadius = 10

        telnumField.translatesAutoresizingMaskIntoConstraints = false
        telnumField.widthAnchor.constraint(equalToConstant: 333).isActive = true
        telnumField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        telnumField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
        telnumField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 445).isActive = true
    }
    
    func setRegisterBtn() {
        registerBtn.frame = CGRect(x: 0, y: 0, width: 299, height: 50)
        registerBtn.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        registerBtn.layer.cornerRadius = 10

        registerBtn.translatesAutoresizingMaskIntoConstraints = false
        registerBtn.widthAnchor.constraint(equalToConstant: 299).isActive = true
        registerBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        registerBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 47).isActive = true
        registerBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 692).isActive = true
        registerBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
    }
    
    func setLable() {
        idLable.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        idLable.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        idLable.textAlignment = .center

        idLable.translatesAutoresizingMaskIntoConstraints = false
        idLable.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
        idLable.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 141).isActive = true
        
        
        pwLable.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        pwLable.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        pwLable.textAlignment = .center

        pwLable.translatesAutoresizingMaskIntoConstraints = false
        pwLable.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
        pwLable.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 232).isActive = true
        
        nameLable.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        nameLable.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        nameLable.textAlignment = .center

        nameLable.translatesAutoresizingMaskIntoConstraints = false
        nameLable.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
        nameLable.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 324).isActive = true
        
        phoneNumLable.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        phoneNumLable.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        phoneNumLable.textAlignment = .center

        phoneNumLable.translatesAutoresizingMaskIntoConstraints = false
        phoneNumLable.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
        phoneNumLable.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 415).isActive = true
        
        selectLable.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        selectLable.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        selectLable.textAlignment = .center

        selectLable.translatesAutoresizingMaskIntoConstraints = false
        selectLable.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
        selectLable.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 521).isActive = true
    }
    
    func setOptBtns() {
        optionBtn[0].frame = CGRect(x: 0, y: 0, width: 160, height: 53)
        optionBtn[0].layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        optionBtn[0].layer.cornerRadius = 10
        optionBtn[0].layer.borderWidth = 1
        optionBtn[0].layer.borderColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor

        optionBtn[0].translatesAutoresizingMaskIntoConstraints = false
        optionBtn[0].widthAnchor.constraint(equalToConstant: 160).isActive = true
        optionBtn[0].heightAnchor.constraint(equalToConstant: 53).isActive = true
        optionBtn[0].leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 36).isActive = true
        optionBtn[0].topAnchor.constraint(equalTo: self.view.topAnchor, constant: 557).isActive = true
        optionBtn[0].tintColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1)
        
        optionBtn[1].frame = CGRect(x: 0, y: 0, width: 160, height: 53)
        optionBtn[1].layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        optionBtn[1].layer.cornerRadius = 10
        optionBtn[1].layer.borderWidth = 1
        optionBtn[1].layer.borderColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        
        optionBtn[1].translatesAutoresizingMaskIntoConstraints = false
        optionBtn[1].widthAnchor.constraint(equalToConstant: 160).isActive = true
        optionBtn[1].heightAnchor.constraint(equalToConstant: 53).isActive = true
        optionBtn[1].leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 195).isActive = true
        optionBtn[1].topAnchor.constraint(equalTo: self.view.topAnchor, constant: 557).isActive = true
        optionBtn[1].tintColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1)
    }
    
    func setNavivgationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 109)
        navigationBar.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        navigationBar.layer.cornerRadius = 10


        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 109).isActive = true
        

        titleLable.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        titleLable.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        titleLable.textAlignment = .center

        titleLable.translatesAutoresizingMaskIntoConstraints = false
        titleLable.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleLable.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 65).isActive = true
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
                
                $0.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                $0.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
                
                
            } else {
                // 다른 tag이면 색이 없는 동그라미로 변경
                $0.tintColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1)
                $0.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
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
