//
//  RegisterCompletedVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import UIKit

class RegisterCompletedVC: UIViewController {

    @IBAction func clickCheckBtn(_ sender: Any) {
        if let presentingVC = self.presentingViewController?.presentingViewController?.presentingViewController {
            // 첫번째 화면(로그인)으로 돌아감
            presentingVC.dismiss(animated: true, completion: nil)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
