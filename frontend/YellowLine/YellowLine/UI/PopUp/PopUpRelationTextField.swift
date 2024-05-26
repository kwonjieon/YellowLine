//
//  PopUpRelationTextField.swift
//  YellowLine
//
//  Created by 정성희 on 5/26/24.
//

import UIKit
import Alamofire

class PopUpRelationTextField: UIViewController {

    @IBAction func clickCancelBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func clickCheckBtn(_ sender: Any) {
        makeRelations()
        self.dismiss(animated: true)
    }
    @IBOutlet weak var idTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        idTextField.delegate = self
        setIDField()
    }
    
    func setIDField() {
        idTextField.placeholder = "피보호자 아이디"
        idTextField.clearButtonMode = .always
        idTextField.returnKeyType = .done
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
