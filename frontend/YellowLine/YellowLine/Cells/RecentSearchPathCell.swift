//
//  RecentSearchPathCell.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import UIKit

class RecentSearchPathCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!{
        didSet{
            
        }
    }
    @IBOutlet weak var showBtn: UIButton!
    @IBAction func clickShowBtn(_ sender: Any) {
        print("show")
    }
    
}
