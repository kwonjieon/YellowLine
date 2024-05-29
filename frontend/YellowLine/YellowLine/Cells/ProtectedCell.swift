//
//  ProtectedCell.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import UIKit

class ProtectedCell: UITableViewCell {
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var statusBtn: UIButton!
    @IBOutlet weak var name: UILabel!
    var protectorMainVC = ProtectorMainVC()
    @IBAction func clickCheckBtn(_ sender: Any) {
        if statusBtn.titleLabel?.text == "네비게이션 및 도보 카메라 확인" {
            
        }
        else if statusBtn.titleLabel?.text == "도보 카메라 확인" {
            print("도보")
            protectorMainVC.loadShowObjectDetection()
        }
    }
}
