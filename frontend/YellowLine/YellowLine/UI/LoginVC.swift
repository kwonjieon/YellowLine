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
    
    @IBAction func clickLoginBtn(_ sender: Any) {
        // 버튼 누르면 키보드가 자동으로 내려감
        PWField.resignFirstResponder()
    }
    @IBAction func clickRegisterBtn(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        PWField.delegate = self
        IDField.delegate = self
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
}
