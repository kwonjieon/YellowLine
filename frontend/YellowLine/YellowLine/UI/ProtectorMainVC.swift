//
//  ProtectorMainVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/24/24.
//

import UIKit
import Alamofire

class ProtectorMainVC: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var relationBtn: UIButton!
    @IBAction func clickRelationBtn(_ sender: Any) {
        let nextVC = self.storyboard?.instantiateViewController(identifier: "PopUpRelationTextField") as! PopUpRelationTextField
        nextVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        self.present(nextVC, animated: true)
    }
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var protectedTableView: UITableView!
    // 서버에서 받을 피보호자 JSON 데이터
    var protectedModel : ProtectedModel?
    
    //
    
    // JSON 데이터를 디코딩한 피보호자 데이터 리스트
    var protectedList : [ResultData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        protectedTableView.dataSource = self
        protectedTableView.delegate = self
        
        setNavivgationBar()
        loadRecipients()
        
        protectedTableView.backgroundColor = UIColor(red: 0.902, green: 0.902, blue: 0.902, alpha: 1)
        self.view.backgroundColor = UIColor(red: 0.902, green: 0.902, blue: 0.902, alpha: 1)
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
                // 연결된 피보호자가 한명도 없다면 ui 리스트 업데이트 안함
                if (self.protectedModel!.results.count != 0 ) {
                    for i in 0...self.protectedModel!.results.count-1 {
                        self.protectedList.append(self.protectedModel!.results[i]!)
                        print(self.protectedModel!.results[i]!.name)
                    }
                    DispatchQueue.main.async {
                        self.protectedTableView.reloadData()
                    }
                }
            }catch{
                print(error)
            }
        })
        dataTask.resume()
    }
    
    // 보호자-피보호자 관계 추가
    func makeRelations() {
        let helper_id = UserDefaults.standard.string(forKey: "uid")!
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
    
    func setRelationBtn() {
        relationBtn.translatesAutoresizingMaskIntoConstraints = false
        relationBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        relationBtn.heightAnchor.constraint(equalToConstant: 60).isActive = true
        relationBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 289).isActive = true
        relationBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 712).isActive = true
    }
    
    func setNavivgationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 109)
        navigationBar.layer.backgroundColor = UIColor(red: 0.324, green: 0.39, blue: 0.989, alpha: 1).cgColor
        navigationBar.layer.cornerRadius = 10


        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 109).isActive = true
        

        titleLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        titleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        titleLabel.textAlignment = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 65).isActive = true
    }
    
    func setBtn(cell : UIButton) {
        // Auto layout, variables, and unit scale are not yet supported
        cell.backgroundColor = UIColor(red: 0.398, green: 0.452, blue: 0.936, alpha: 1)
        cell.layer.cornerRadius = 10
        
        var shadows = UIView()
        shadows.frame = cell.frame
        shadows.clipsToBounds = false
        cell.addSubview(shadows)

        let shadowPath0 = UIBezierPath(roundedRect: shadows.bounds, cornerRadius: 10)
        let layer0 = CALayer()
        layer0.shadowPath = shadowPath0.cgPath
        layer0.shadowColor = UIColor(red: 0.08, green: 0, blue: 1, alpha: 0.25).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 10
        layer0.shadowOffset = CGSize(width: 0, height: 0)
        layer0.bounds = shadows.bounds
        layer0.position = shadows.center
        shadows.layer.addSublayer(layer0)

        var shapes = UIView()
        shapes.frame = cell.frame
        shapes.clipsToBounds = true
        cell.addSubview(shapes)

        let layer1 = CALayer()
        layer1.backgroundColor = UIColor(red: 0.398, green: 0.452, blue: 0.936, alpha: 1).cgColor
        layer1.bounds = shapes.bounds
        layer1.position = shapes.center
        shapes.layer.addSublayer(layer1)
        shapes.layer.cornerRadius = 10
        
    }
    
   
    func loadShowObjectDetection() {
        
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "ShowObjectDetectionVC") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
    }
    
   // cell 의 버튼 클릭 시 네비 or 물체탐지 경우 확인 후 페이지 로드
    @objc func checkBoxButtonTapped(sender: UIButton) {
        if sender.titleLabel?.text == "도보 카메라 확인" {
            let nextVC = self.storyboard?.instantiateViewController(identifier: "ShowObjectDetectionVC") as! ShowObjectDetectionVC
            nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            
            // 피보호자 이름, 아이디 전달
            nextVC.name = protectedList[sender.tag].name
            nextVC.id = protectedList[sender.tag].id
        
            self.present(nextVC, animated: true)
        }
        else if sender.titleLabel?.text == "네비게이션 및 도보 카메라 확인" {
            let nextVC = self.storyboard?.instantiateViewController(identifier: "ShowNavigationVC") as! ShowNavigationVC
            nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            getProtectedDestination(id: protectedList[sender.tag].id)
            
            // 피보호자 이름, 아이디 전달
            nextVC.name = protectedList[sender.tag].name
            nextVC.id = protectedList[sender.tag].id
            
            self.present(nextVC, animated: true)
        }
    }
    
    func getProtectedDestination(id : String) {
        print ("id : \(id)")
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let URL = "http://43.202.136.75/user/protected-info/"
        let tmpData : [String : String] = ["user_id" : id]
        AF.upload(multipartFormData: { multipartFormData in for (key, val) in tmpData {
            multipartFormData.append(val.data(using: .utf8)!, withName: key)
        }
        },to: URL, method: .post, headers: header)
        .responseDecodable(of: DestinationResult.self){ response in
            DispatchQueue.main.async {
                switch response.result {
                case let .success(response):
                    print("불러오기 성공")
                    let result = response
                    // error가 없으면 통과
                    guard let resOption = result.recent_arrival else {
                        return
                    }
                    print(resOption)
                    let cType = resOption
                    
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
}

struct DestinationResult : Codable {
    let user_id : String?
    let user_name : String?
    let recent_arrival : String?
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
        return 107
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProtectedCell", for: indexPath)as! ProtectedCell
        cell.name.text = protectedList[indexPath.row].name
        
        // cell 뷰 디자인
        cell.cellView.layer.cornerRadius = 10
        cell.backgroundColor = .clear
        setBtn(cell: cell.statusBtn)
        cell.statusBtn.titleLabel?.text = protectedList[indexPath.row].latest_state
        
        // 버튼 구별
        cell.statusBtn.tag = indexPath.row
        cell.statusBtn.addTarget(self, action: #selector(checkBoxButtonTapped(sender:)), for: .touchUpInside)
        
        // 피보호자가 오프라인 상태인 경우
        if (protectedList[indexPath.row].latest_state == "Offline") {
            cell.statusBtn.backgroundColor = UIColor(red: 0.661, green: 0.661, blue: 0.661, alpha: 1)
            cell.statusBtn.layer.cornerRadius = 10
            cell.statusBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            cell.statusBtn.setTitle("오프라인 상태", for: .normal)
            
            cell.cellView.backgroundColor = UIColor(red: 0.787, green: 0.787, blue: 0.787, alpha: 1)
        }
        // 피보호자가 네비 사용중인 경우
        else if (protectedList[indexPath.row].latest_state == "Navigation") {
            cell.statusBtn.backgroundColor = UIColor(red: 0.398, green: 0.452, blue: 0.936, alpha: 1)
            cell.statusBtn.layer.cornerRadius = 10
            cell.statusBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            cell.statusBtn.setTitle("네비게이션 및 도보 카메라 확인", for: .normal)
        }
        // 피보호자가 물체탐지 사용중인 경우
        else {
            cell.statusBtn.backgroundColor = UIColor(red: 0.398, green: 0.452, blue: 0.936, alpha: 1)
            cell.statusBtn.layer.cornerRadius = 10
            cell.statusBtn.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            cell.statusBtn.setTitle("도보 카메라 확인", for: .normal)
        }
        
        // cell 누르고 있거나 눌렀을 때 배경색 안바뀌게 유지
        let background = UIView()
        background.backgroundColor = .clear
        cell.selectedBackgroundView = background
        
        return cell
    }
}
