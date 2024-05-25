//
//  PopUpInformVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/23/24.
//

import UIKit

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
        // 회원가입 성공시 성공 안내 화면으로 이동
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "RegisterCompletedVC") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
    }
}
