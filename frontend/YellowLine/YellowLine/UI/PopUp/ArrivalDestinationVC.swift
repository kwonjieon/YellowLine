//
//  ArrivalDestinationVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/29/24.
//

import UIKit

class ArrivalDestinationVC: UIViewController {
    
    
    @IBOutlet weak var descriptionLabel1: UILabel!
    @IBOutlet weak var descriptionLabel2: UILabel!
    @IBOutlet weak var popView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionStack: UIStackView!
    
    @IBOutlet weak var checkBtn: UIButton!
    @IBAction func clickCheckBtn(_ sender: Any) {
        if let presentingVC = self.presentingViewController?.presentingViewController?.presentingViewController?.presentingViewController {
            // 메인화면으로 돌아감
            presentingVC.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setPopView()
        setLabel()
        setBtn()
    }
    
    func setPopView() {
        popView.frame = CGRect(x: 0, y: 0, width: 350, height: 205)
        popView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        popView.layer.cornerRadius = 10

        popView.translatesAutoresizingMaskIntoConstraints = false
        popView.widthAnchor.constraint(equalToConstant: 350).isActive = true
        popView.heightAnchor.constraint(equalToConstant: 205).isActive = true
        popView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 21).isActive = true
        popView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 320).isActive = true
    }
    
    func setLabel() {
        titleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: popView.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: popView.topAnchor, constant: 39).isActive = true
        
        descriptionStack.translatesAutoresizingMaskIntoConstraints = false
        descriptionStack.centerXAnchor.constraint(equalTo: popView.centerXAnchor).isActive = true
        descriptionStack.topAnchor.constraint(equalTo: popView.topAnchor, constant: 73).isActive = true
        
        descriptionLabel1.textColor = UIColor(red: 0.539, green: 0.539, blue: 0.539, alpha: 1)
        descriptionLabel2.textColor = UIColor(red: 0.539, green: 0.539, blue: 0.539, alpha: 1)
        
        
    }
    
    func setBtn() {
        checkBtn.frame = CGRect(x: 0, y: 0, width: 297, height: 44)
        checkBtn.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        checkBtn.layer.cornerRadius = 10

        checkBtn.translatesAutoresizingMaskIntoConstraints = false
        checkBtn.widthAnchor.constraint(equalToConstant: 297).isActive = true
        checkBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        checkBtn.leadingAnchor.constraint(equalTo: popView.leadingAnchor, constant: 28).isActive = true
        checkBtn.topAnchor.constraint(equalTo: popView.topAnchor, constant: 136).isActive = true
        checkBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
}
