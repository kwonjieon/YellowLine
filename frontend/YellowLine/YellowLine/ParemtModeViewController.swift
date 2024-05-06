//
//  ParemtModeViewController.swift
//  YellowLine
//
//  Created by 이종범 on 5/6/24.
//

import Foundation
import UIKit

struct ChildList {
    func showlist() -> UIView {
        var view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        view.layer.backgroundColor = UIColor(red: 0.114, green: 0.114, blue: 0.114, alpha: 1).cgColor
        view.layer.cornerRadius = 50
        
        return view
    }
}
