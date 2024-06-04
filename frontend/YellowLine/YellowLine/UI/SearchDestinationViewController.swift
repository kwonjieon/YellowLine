//
//  SearchDestinationViewController.swift
//  YellowLine
//
//  Created by 정성희 on 4/8/24.
//

import UIKit
import TMapSDK
import Foundation
import Alamofire
struct Coordinate {
    let latitude: Double
    let longitude: Double
}
class SearchDestinationViewController: UIViewController, TMapViewDelegate {
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    
    var destinationModel : DestinationModel?
    var destinationList : [String] = [] // 목적지 검색 리스트 데이터
    
    var searchHistoryModel : SearchHistoryResult?
    var searchHistoryList : [UserHistory] = []
    
    var selectDestinationName : String?
    var selectDestinationLati : String?
    var selectDestinationLongi : String?
    
    var navigationDataModel : NavigationDataModel?
    var navigationList : [String] = [] // 네비게이션 경로 데이터
    var naviDestinationList: [String] = [] // 목적지
    var naviPointList : [String] = [] // 경로 중 좌, 우회전 해야하는 경/위도 리스트
    static var pointDict: [String: String] = [:] // 좌/우회전 해야하는 위치 포인트 딕셔너리, 범위 조정이 된 상태임
    static var pointerDataList: [LocationData] = []
    
    // 검색 시작 후에 최근 경로 대신 검색한 리스트 값을 호출하기 위한 flag 값
    var startSearch = false
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var listTableView: UITableView!
    
    @IBOutlet weak var recentSearchLabel: UILabel!
    
    @IBAction func backBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBOutlet weak var navigationBar: UIView!
    
    deinit {
        print("*SearchDestination Deinit...")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSearchHistory()
        
        searchBar.delegate = self
        
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)
        
        listTableView.backgroundColor = .white
        
        listTableView.delegate = self
        listTableView.dataSource = self
        
        self.view.backgroundColor = .white
        //setNaviBar()
        setSearchBar()
        setNavivgationBar()
    }
    
    func setNavivgationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 109)
        navigationBar.layer.backgroundColor = UIColor(red: 1, green: 0.841, blue: 0.468, alpha: 1).cgColor
        navigationBar.layer.cornerRadius = 20

        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.widthAnchor.constraint(equalToConstant: 393).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 109).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
    }
    
    func setSearchBar() {
        searchBar.placeholder = "목적지를 입력해주세요"
        //searchBar.setImage(UIImage(named: "search-icon"), for: UISearchBar.Icon.search, state: .normal)
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor(red: 0.885, green: 0.885, blue: 0.885, alpha: 1)
        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            textfield.backgroundColor = .clear
            textfield.textColor = UIColor.black
            textfield.font = UIFont(name: "AppleSDGothicNeoM00-Regular", size: 16)
        }
        
        // 키보드에 return 표기
        searchBar.returnKeyType = .done
        searchBar.layer.cornerRadius = 20
        
        // Auto Layout 설정
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // 개별 제약 조건 활성화
        searchBar.widthAnchor.constraint(equalToConstant: 361).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
        searchBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 128).isActive = true
        
    }
    
    func setNaviBar() {
        // safe area
        var statusBarHeight: CGFloat = 0
        statusBarHeight = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        
        // navigationBar
        let naviBar = UINavigationBar(frame: .init(x: 0, y: statusBarHeight, width: view.frame.width, height: statusBarHeight))
        naviBar.isTranslucent = false
        
        // 네비게이션 바의 배경 이미지를 설정하여 둥근 모서리를 표현
        if let backgroundImage = UIImage(named: "SearchNaviBar") {
            naviBar.setBackgroundImage(backgroundImage, for: .default)
        }
        
        let naviItem = UINavigationItem(title: "title")
        naviItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(test))
        naviBar.items = [naviItem]
        
        view.addSubview(naviBar)
    }
    
    @objc func test() {
        print("click")
    }
    
    // 목적지 검색 기록 저장
    func saveSearchHistory() {
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = "http://43.202.136.75/user/routeSearch/"
        
        guard let text = searchBar.text else {
            return
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(text.data(using:.utf8)!, withName: "arrival")
        }, to: loginURL, method: .post, headers: header)
        .responseDecodable(of: RouteSearchResult.self){ response in
            DispatchQueue.main.async {
                switch response.result {
                case let .success(response):
                    let result = response
                    // error가 없으면 통과
                    guard let resOption = result.success else {
                        return
                    }
                    let cType = resOption
                    switch cType{
                        
                    case true:
                        print("저장성공")
                        break
                    default:
                        print("저장실패")
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
    
    // 목적지 검색 기록 로드
    func loadSearchHistory() {
        let headers = ["Accept": "application/json"]
        let requestStr: String = "http://43.202.136.75/user/recent/"
        
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
            //데이터 디코딩
            do{
                self.searchHistoryModel = try JSONDecoder().decode(SearchHistoryResult.self, from: data!)
                if self.searchHistoryModel!.user_history.count != 0 {
                    for i in 0...self.searchHistoryModel!.user_history.count-1 {
                        self.searchHistoryList.append(self.searchHistoryModel!.user_history[i]!)
                        print(self.searchHistoryModel!.user_history[i]?.arrival)
                    }
                    DispatchQueue.main.async {
                        self.listTableView.reloadData()
                    }
                }
            }catch{
                print(error)
            }
        })
        dataTask.resume()
    }
    
    // 목적지 리스트 API 요청
    func getTMapAPISearchDestination(searchStr: String, count: Int) {
        let headers = [
            "Accept": "application/json",
            "appKey": "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
        ]
        let requestStr: String = "https://apis.openapi.sk.com/tmap/pois?version=1&searchKeyword=" + searchStr + "&searchType=all&searchtypCd=A&reqCoordType=WGS84GEO&resCoordType=WGS84GEO&page=1&count=" + String(count) + "&multiPoint=N&poiGroupYn=N"
        
        guard let encodedStr = requestStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let request = NSMutableURLRequest(url: NSURL(string: encodedStr)! as URL,
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
                self.destinationList.removeAll()
                self.destinationModel = try JSONDecoder().decode(DestinationModel.self, from: data!)
                for i in 0...self.destinationModel!.searchPoiInfo.pois.poi.count-1 {
                    self.destinationList.append(self.destinationModel!.searchPoiInfo.pois.poi[i].name)
                }
                
                
                DispatchQueue.main.async {
                    if (self.startSearch == false) {
                        self.startSearch = true
                        self.recentSearchLabel.isHidden = true
                    }
                    self.listTableView.reloadData()
                }
                print(self.destinationList)
            }catch{
                print(error)
            }
        })
        dataTask.resume()
    }
    
    // 목적지까지의 도보 네비게이션 주행 정보 API 요청
    func getTMapAPINavigationInform() {
        let headers = [
            "accept": "application/json",
            "content-type": "application/json",
            "appKey": "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
        ]
        let parameters = [
            // 집 37.53943759237482 127.21876285658607
            // 학정 입구 127.07412355017871,37.551447232646765
            // 가츠시 127.07570314407349 37.54633818154831
            // 알바 37.54089617063285 127.22094921007677
            // 어대공 6번출구 37.54885914948882, 127.07501188046824
            "startX": 127.07412355017871,
            "startY": 37.551447232646765,
            "angle": 20,
            "speed": 30,
            "endPoiId": "10001",
            "endX": 127.07501188046824,
            "endY": 37.54885914948882,
            "reqCoordType": "WGS84GEO",
            "startName": "%EC%B6%9C%EB%B0%9C",
            "endName": "%EB%8F%84%EC%B0%A9",
            "searchOption": "0",
            "resCoordType": "WGS84GEO",
            "sort": "index"
        ] as [String : Any]
        
        do{
            let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            let request = NSMutableURLRequest(url: NSURL(string: "https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&callback=function")! as URL,
                                              cachePolicy: .useProtocolCachePolicy,timeoutInterval: 10.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData as Data
            
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    print(error as Any)
                } else {
                    let httpResponse = response as? HTTPURLResponse
                    print(httpResponse)
                }
                //데이터 디코딩
                // 목적지 선택 후, 지정된 목적지로 포인트들 탐색 후 mapvie 에서 데이터 사용
                do{
                    self.navigationDataModel = try JSONDecoder().decode(NavigationDataModel.self, from: data!)
                    for i in 0...self.navigationDataModel!.features.count-1 {
                        //print(self.navigationDataModel!.features[i].properties.description!)
                        
                        
                        if let destinationInput = self.navigationDataModel!.features[i].properties.nearPoiName {
                            if destinationInput != "" {
                                self.naviDestinationList.append(destinationInput)
                            }
                        }
                        
                        // 목적지까지의 좌/우 회전 경로 저장
                        switch self.navigationDataModel!.features[i].geometry.coordinates {
                            // 1차원 배열인 경우 -> 경로가 아닌 장소 포인트를 의미
                        case .oneDimensional(let array):
                            let description = self.navigationDataModel!.features[i].properties.description!
                            print(description)
                            // 좌회전 또는 우회전 단어가 포함된 description만 좌/우 방향회전 장소 포인트이므로 단어 포함 확인
                            if description.contains("좌회전") || description.contains("우회전") {
                                self.navigationList.append(self.navigationDataModel!.features[i].properties.description!)
                                
                                // 위치 및 방향 데이터 객체 생성 및 삽입
                                var inputData: LocationData = LocationData()
                                inputData.latitude = array[1]
                                inputData.longitude = array[0]
                                inputData.name = self.navigationDataModel!.features[i].properties.nearPoiName!
                                
                                if description.contains("좌회전") {
                                    inputData.direction = "좌회전"
                                }
                                else {
                                    inputData.direction = "우회전"
                                }
                                SearchDestinationViewController.pointerDataList.append(inputData)
                            }
                        case .twoDimensional(let array): break
                        }
                    }
                    print(self.navigationList)
                    print(self.naviDestinationList)
                }catch{
                    print(error)
                }
            })
            dataTask.resume()
        }catch{
            print(error)
        }
    }
    
    
    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
}

// 입력된 목적지 검색 시 API 요청 시도
extension SearchDestinationViewController:UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        getTMapAPISearchDestination(searchStr: searchBar.text!, count: 20)
        //saveSearchHistory()
    }
    
    // 키보드 외 다른 영역 클릭 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // 키보드 리턴(확인) 입력 시 키보드 내리기
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchBar.resignFirstResponder()
        return true
    }
}

struct RouteSearchResult : Codable {
    let success : Bool?
    let message : String?
}

struct SearchHistoryResult : Codable {
    let user_history : [UserHistory?]
}

struct UserHistory : Codable {
    let historyNum : Int
    let user_id : String
    let arrival : String
    let latitude : String
    let longitude : String
    let time : String
}

extension SearchDestinationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if (startSearch == true) {
            return destinationList.count
        }
        else {
            return searchHistoryList.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (startSearch == true) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell", for: indexPath)as! DestinationCell
            cell.locationLabel.text = destinationList[indexPath.row]
            cell.locationLabel.textColor = .black
            cell.locationLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
            
            cell.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.00)
            
            // cell 누르고 있거나 눌렀을 때 배경색 안바뀌게 유지
            /*
            let background = UIView()
            background.backgroundColor = .clear
            cell.selectedBackgroundView = background
             */
            return cell
        }
        
        else {
            print ("데이터 불러오기 ok")
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell", for: indexPath)as! DestinationCell
            cell.locationLabel.text = searchHistoryList[indexPath.row].arrival
            cell.locationLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
            cell.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.00)
            
            // cell 누르고 있거나 눌렀을 때 배경색 안바뀌게 유지
            /*
            let background = UIView()
            background.backgroundColor = .clear
            cell.selectedBackgroundView = background
             */
            return cell
             
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // example height for each row
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }

    // row 클릭 시
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextVC = self.storyboard?.instantiateViewController(identifier: "SelectDestinationVC") as! SelectDestinationVC
        nextVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        
        // 목적지 검색
        if (startSearch == true) {
            // 클릭한 목적지 데이터 같이 전송
            nextVC.destinationName = destinationList[indexPath.row]
            nextVC.destinationLati = self.destinationModel!.searchPoiInfo.pois.poi[indexPath.row].frontLat
            nextVC.destinationLongi = self.destinationModel!.searchPoiInfo.pois.poi[indexPath.row].frontLon
            nextVC.isRecentSeleted = false
        }
        // 최근 경로
        else {
            // 클릭한 목적지 데이터 같이 전송
            nextVC.destinationName = searchHistoryList[indexPath.row].arrival
            nextVC.destinationLati = searchHistoryList[indexPath.row].latitude
            nextVC.destinationLongi = searchHistoryList[indexPath.row].longitude
            nextVC.isRecentSeleted = true
        }
        
        self.present(nextVC, animated: true)
        
        
        // 한번 클릭 한 row 클릭상태 ui 바로 해제
        //tableView.deselectRow(at: indexPath, animated: true)
    }
}
