//
//  ShowNavigationVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/30/24.
//

import UIKit

// 보호자가 보는 피보호자의 네비+물체감지 화면
class ShowNavigationVC: UIViewController {
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var objectDetectionView: UIView!
    @IBOutlet weak var backBtn: UIButton!
    @IBAction func clickBackBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setObjectDetectionView()
        setBackBtn()
        setNameLabel()
        setNavigationBar()
    }
    
    func setObjectDetectionView() {
        objectDetectionView.frame = CGRect(x: 0, y: 0, width: 394.09, height: 356)
        objectDetectionView.layer.backgroundColor = UIColor(red: 0.851, green: 0.851, blue: 0.851, alpha: 1).cgColor
        objectDetectionView.layer.cornerRadius = 20

        objectDetectionView.translatesAutoresizingMaskIntoConstraints = false
        objectDetectionView.widthAnchor.constraint(equalToConstant: 394.09).isActive = true
        objectDetectionView.heightAnchor.constraint(equalToConstant: 356).isActive = true
        objectDetectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        objectDetectionView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 496).isActive = true
    }
    
    func setBackBtn() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 33).isActive = true
        backBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
    }
    
    func setNameLabel() {
        nameLabel.text = name
        nameLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        nameLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        nameLabel.textAlignment = .center

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 59).isActive = true
    }
    
    func setNavigationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 126)
        navigationBar.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor

        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 126).isActive = true
    }
}
