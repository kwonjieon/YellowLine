//
//  ObjectDetectionVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/30/24.
//

import UIKit

class ObjectDetectionVC: UIViewController {
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBAction func clickBackBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func setNavigationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 120)
        navigationBar.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        navigationBar.layer.cornerRadius = 20

        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }
    
    func setLabel() {
        
    }

}
