//
//  SearchDestinationViewController.swift
//  YellowLine
//
//  Created by 정성희 on 4/8/24.
//

import UIKit
import TMapSDK
import Foundation
struct Coordinate {
    let latitude: Double
    let longitude: Double
}
class SearchDestinationViewController: UIViewController, TMapViewDelegate {
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    
    var navigationDataModel : NavigationDataModel?
    var destinationModel : DestinationModel?
    var navigationList : [String] = [] // 네비게이션 경로 데이터
    var destinationList : [String] = [] // 목적지 검색 리스트 데이터
    var naviDestinationList: [String] = [] // 목적지
    var naviPointList : [String] = [] // 경로 중 좌, 우회전 해야하는 경/위도 리스트
    static var pointDict: [String: String] = [:] // 좌/우회전 해야하는 위치 포인트 딕셔너리, 범위 조정이 된 상태임
    static var pointerDataList: [LocationData] = []
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBAction func getTMapAPINavigationInformBtn(_ sender: Any) {
        getTMapAPINavigationInform()
    }
    @IBAction func backBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func loadMap(_ sender: Any) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "MapViewController") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(nextVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)
    }
    
    // 목적지 리스트 API 요청
    func getTMapAPISearchDestination(searchStr: String) {
        let headers = [
            "Accept": "application/json",
            "appKey": "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
        ]
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://apis.openapi.sk.com/tmap/pois?version=1&searchKeyword=%EC%84%B8%EC%A2%85%EB%8C%80%ED%95%99%EA%B5%90&searchType=all&searchtypCd=A&reqCoordType=WGS84GEO&resCoordType=WGS84GEO&page=1&count=20&multiPoint=N&poiGroupYn=N")! as URL,
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
                self.destinationModel = try JSONDecoder().decode(DestinationModel.self, from: data!)
                for i in 0...self.destinationModel!.searchPoiInfo.pois.poi.count-1 {
                    //print(self.destinationModel!.searchPoiInfo.pois.poi[i].name)
                    self.destinationList.append(self.destinationModel!.searchPoiInfo.pois.poi[i].name)
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


    
    // 포인트리스트 값을 입력하면 뒷자리가 잘린(범위가 넓어진) 포인트 리스트 반환
    // 포인트 근접인정 범위 계산 함수
    func pointRangeChange (latitude: Double, longitude: Double) -> Coordinate {
        let centerCoordinate = Coordinate(latitude: 37.54748588, longitude: 127.07295740) // 값 계산을 위한 임시 값
        let radiusInMeters = 30.0 // 경로안내 범위지정, m 단위

        // 위도, 경도 범위 알아냄
        let boundingBox = calculateBoundingBox(center: centerCoordinate, radius: radiusInMeters)
        // 위도, 경도 범위의 반경값 = 특정 위도, 경도 값을 기준으로 몇 미터 이내까지 가도 되는가?
        let radius = (boundingBox.maxLatitude - boundingBox.minLatitude) / 2
        // 0.00003425
        
        // 반경값이 몇자리의 값인가?
        let roundDownNumber = decimalPlaceCount(radius)
        
        // 원하는 소수점 자리 이후로 값 삭제
        let resultLatitude = truncateDecimalPlaces(latitude, afterDecimalPlaces: roundDownNumber)
        let resultLongitude = truncateDecimalPlaces(longitude, afterDecimalPlaces: roundDownNumber)
        
        return Coordinate(latitude: resultLatitude, longitude: resultLongitude)
    }
    
    func calculateBoundingBox(center: Coordinate, radius: Double) -> (minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) {
        let latDistance = radius / 111111.0 // 1도의 위도 차이는 약 111,111 미터
        let lonDistance = radius / (111111.0 * cos(degreesToRadians(center.latitude))) // 경도는 위도에 따라 변할 수 있음

        let minLatitude = center.latitude - latDistance
        let maxLatitude = center.latitude + latDistance
        let minLongitude = center.longitude - lonDistance
        let maxLongitude = center.longitude + lonDistance

        return (minLatitude, maxLatitude, minLongitude, maxLongitude)
    }
    
    // 소수점 자리수 알아내는 함수
    func decimalPlaceCount(_ number: Double) -> Int {
        // 절대값을 취합니다.
        var absoluteValue = abs(number)
        
        // 로그를 이용해 소수 자리수를 구합니다.
        let decimalPlace = log10(absoluteValue)
        
        absoluteValue = abs(decimalPlace)
        
        return Int(ceil(absoluteValue))
    }
    
    // 특정 소수점 이후의 값을 버리는 함수
    func truncateDecimalPlaces(_ number: Double, afterDecimalPlaces n: Int) -> Double {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = n
        
        if let truncatedString = formatter.string(from: NSNumber(value: number)) {
            return Double(truncatedString) ?? 0.0
        } else {
            return 0.0
        }
    }
}

// 입력된 목적지 검색 시 API 요청 시도
extension SearchDestinationViewController:UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        getTMapAPISearchDestination(searchStr: searchBar.text!)
    }
}
