//
//  DestinationCell.swift
//  YellowLine
//
//  Created by 정성희 on 5/17/24.
//

import Foundation
import UIKit
class DestinationCell: UITableViewCell, UITableViewDelegate {
    @IBOutlet weak var locationLabel: UILabel! {
        didSet {
            locationLabel.font = UIFont(name: "AppleSDGothicNeoB", size: 18)
            print("리스트 생성")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 4, right: 16))
    }
}
