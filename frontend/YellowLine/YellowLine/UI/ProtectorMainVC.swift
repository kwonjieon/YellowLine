//
//  ProtectorMainVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import UIKit
import Alamofire

class ProtectorMainVC: UIViewController {
    @IBAction func clickRelationBtn(_ sender: Any) {
        let nextVC = self.storyboard?.instantiateViewController(identifier: "PopUpRelationTextField") as! PopUpRelationTextField
        nextVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        self.present(nextVC, animated: true)
    }
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
        loadRecipients()
        
        protectedTableView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.00)
    }
    
    // 피보호자 리스트 불러오기
    func loadRecipients() {
        
        let headers = ["Accept": "application/json"]
        let requestStr: String = "http://43.202.136.75/user/relations/"
        
        let request = NSMutableURLRequest(url: NSURL(string: requestStr)! as URL,
                                          cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error as Any)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
            print("data :::: \(data!)")
            //데이터 디코딩
            do{
                self.protectedModel = try JSONDecoder().decode(ProtectedModel.self, from: data!)
                for i in 0...self.protectedModel!.results.count-1 {
                    self.protectedList.append(self.protectedModel!.results[i]!)
                    print(self.protectedModel!.results[i]!.name)
                }
                DispatchQueue.main.async {
                    self.protectedTableView.reloadData()
                }
            }catch{
                print(error)
            }
        })
        dataTask.resume()
    }
    
    func makeRelations() {
        let helper_id = LoginVC.protectorID
        print("보호자 아이디:\(helper_id)")
        let recipient_id = "testID"
        
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let makeRelationsURL = "http://43.202.136.75/user/makerelations/"
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(helper_id.data(using:.utf8)!, withName: "helper_id")
            multipartFormData.append(recipient_id.data(using:.utf8)!, withName: "recipient_id")
        }, to: makeRelationsURL, method: .post, headers: header)
        .responseDecodable(of: MakeRelationResult.self){ response in
            //결과.
            DispatchQueue.main.async {
                switch response.result {
                case let .success(response):
                    let result = response
                    // error가 없으면
                    guard let resOption = result.success else {
                        return
                    }
                    let cType = resOption
                    print(cType)
                    switch cType{
                        
                    case true:
                        print("관계 추가 성공")
                        break
                    default:
                        print("관계 추가 실패")
                        print(result.message)
                        break
                    }
                case let .failure(error):
                    print(error)
                    print("실패입니다.")
                    
                default:
                    print("something wrong...")
                    break
                }
            }
        } //Alamofire request end...
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

struct MakeRelationResult : Codable {
    let success : Bool?
    let message : String?
}

extension ProtectorMainVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return protectedList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProtectedCell", for: indexPath)as! ProtectedCell
        cell.name.text = protectedList[indexPath.row].name
        cell.statusBtn.titleLabel?.text = protectedList[indexPath.row].latest_state
        return cell
    }
}
