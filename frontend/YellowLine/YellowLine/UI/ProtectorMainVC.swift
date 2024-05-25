//
//  ProtectorMainVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import UIKit

class ProtectorMainVC: UIViewController {
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var protectedTableView: UITableView!
    // 서버에서 받을 피보호자 JSON 데이터
    var protectedModel : ProtectedModel?
    
    // JSON 데이터를 디코딩한 피보호자 데이터 리스트
    var protectedList : [ResultData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        protectedTableView.dataSource = self
        protectedTableView.delegate = self
        
        setNavivgationBar()
        network()
        
        protectedTableView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.00)
    }
    
    // 테스트 필요함
    func network() {
        // URL 생성
        let url = URL(string: "http://yellowline-demo.duckdns.org/ "+"user/relations")!
        
        // 헤더 설정
        let headers = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        // URLRequest 인스턴스 생성
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        // 작업 요청
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                // 데이터를 디코딩 (JSON 예제)
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                
                self.protectedModel = try JSONDecoder().decode(ProtectedModel.self, from: data)
                for i in 0...self.protectedModel!.results.count {
                    self.protectedList.append(self.protectedModel!.results[i])
                }
                print("Response JSON: \(jsonResponse)")
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func setNavivgationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 128)
        navigationBar.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        navigationBar.layer.cornerRadius = 20

        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 128).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        
    }
    
}

extension ProtectorMainVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return protectedList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProtectedCell", for: indexPath)as! ProtectedCell
        cell.name.text = protectedList[indexPath.row].name
        
        return cell
    }
}
