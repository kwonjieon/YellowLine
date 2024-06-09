//
//  PopUpRelationTextField.swift
//  YellowLine
//
//  Created by 정성희 on 5/26/24.
//

import UIKit
import Alamofire

class PopUpRelationTextField: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var checkBtn: UIButton!
    @IBOutlet weak var popView: UIView!
    
    @IBAction func clickCancelBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func clickCheckBtn(_ sender: Any) {
        makeRelations()
        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        idTextField.delegate = self
        setIDField()
        setLabel()
        setPopView()
        setBtn()
    }
    
    func setIDField() {
        idTextField.placeholder = "피보호자 아이디"
        idTextField.clearButtonMode = .always
        idTextField.returnKeyType = .done
        
        //idTextField.frame.size.height = 44
        //idTextField.borderStyle = .roundedRect
        

        idTextField.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        idTextField.layer.backgroundColor = UIColor(red: 0.922, green: 0.922, blue: 0.922, alpha: 1).cgColor
        idTextField.layer.cornerRadius = 10

        idTextField.translatesAutoresizingMaskIntoConstraints = false
        idTextField.widthAnchor.constraint(equalToConstant: 300).isActive = true
        idTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        idTextField.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 25).isActive = true
        idTextField.topAnchor.constraint(equalTo: popView.topAnchor, constant: 109).isActive = true
    }
    
    func setLabel() {
        titleLabel.text = "피보호자 연결"
        titleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 22)
        titleLabel.textAlignment = .center
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 115).isActive = true
        titleLabel.topAnchor.constraint(equalTo: popView.topAnchor, constant: 37).isActive = true
        
        descriptionLabel.text = "연결하고 싶은 피보호자의 아이디를 입력해 주세요."
        descriptionLabel.textColor = UIColor(red: 0.539, green: 0.539, blue: 0.539, alpha: 1)
        descriptionLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 16)
        descriptionLabel.textAlignment = .center
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 17).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: popView.topAnchor, constant: 73).isActive = true
    }
    
    func setPopView() {
        popView.frame = CGRect(x: 0, y: 0, width: 350, height: 240)
        popView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        popView.layer.cornerRadius = 10

        popView.translatesAutoresizingMaskIntoConstraints = false
        popView.widthAnchor.constraint(equalToConstant: 350).isActive = true
        popView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        popView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 21).isActive = true
        popView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 285).isActive = true
    }
    
    func setBtn() {
        cancelBtn.frame = CGRect(x: 0, y: 0, width: 142, height: 44)
        cancelBtn.layer.backgroundColor = UIColor(red: 0.857, green: 0.855, blue: 0.89, alpha: 1).cgColor
        cancelBtn.layer.cornerRadius = 10

        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.widthAnchor.constraint(equalToConstant: 142).isActive = true
        cancelBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        cancelBtn.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 25).isActive = true
        cancelBtn.topAnchor.constraint(equalTo: popView.topAnchor, constant: 171).isActive = true
        cancelBtn.tintColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
        
        checkBtn.frame = CGRect(x: 0, y: 0, width: 142, height: 44)
        checkBtn.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        checkBtn.layer.cornerRadius = 10

        checkBtn.translatesAutoresizingMaskIntoConstraints = false
        checkBtn.widthAnchor.constraint(equalToConstant: 142).isActive = true
        checkBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        checkBtn.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 183).isActive = true
        checkBtn.topAnchor.constraint(equalTo: popView.topAnchor, constant: 171).isActive = true
        checkBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    func setTextField() {
        
    }
    
    func makeRelations() {
        let helper_id = LoginVC.protectorID
        let recipient_id = idTextField.text!
        
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let makeRelationsURL = "http://43.202.136.75/user/makerelations/"
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(helper_id.data(using:.utf8)!, withName: "helper_id")
            multipartFormData.append(recipient_id.data(using:.utf8)!, withName: "recipient_id")
        }, to: makeRelationsURL, method: .post, headers: header)
        .responseDecodable(of: MakeRelationResult.self){ response in
            //결과.
            DispatchQueue.main.async {
                switch response.result {
                case let .success(response):
                    let result = response
                    // error가 없으면
                    guard let resOption = result.success else {
                        return
                    }
                    let cType = resOption
                    switch cType{
                        
                    case true:
                        break
                    default:
                        print(result.message)
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
}

extension PopUpRelationTextField: UITextFieldDelegate {
    // 키보드 외 다른 영역 클릭 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // 키보드 리턴(확인) 입력 시 키보드 내리기
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        idTextField.resignFirstResponder()
        return true
    }
}
