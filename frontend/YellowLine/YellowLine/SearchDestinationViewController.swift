//
//  SearchDestinationViewController.swift
//  YellowLine
//
//  Created by 정성희 on 4/8/24.
//

import UIKit
import TMapSDK
import Foundation
class SearchDestinationViewController: UIViewController, TMapViewDelegate {
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    
    var navigationDataModel : NavigationDataModel?
    var destinationModel : DestinationModel?
    var navigationList : [String] = []
    var destinationList : [String] = []
    
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
          "startX": 126.92365493654832,
          "startY": 37.556770374096615,
          "angle": 20,
          "speed": 30,
          "endPoiId": "10001",
          "endX": 126.92432158129688,
          "endY": 37.55279861528311,
          "passList": "126.92774822,37.55395475_126.92577620,37.55337145",
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
                do{
                    self.navigationDataModel = try JSONDecoder().decode(NavigationDataModel.self, from: data!)
                    for i in 0...self.navigationDataModel!.features.count-1 {
                        //print(self.navigationDataModel!.features[i].properties.description!)
                        self.navigationList.append(self.navigationDataModel!.features[i].properties.description!)
                    }
                    print(self.navigationList)
                }catch{
                    print(error)
                }
            })
            dataTask.resume()
        }catch{
            print(error)
        }
    }
}

// 입력된 목적지 검색 시 API 요청 시도
extension SearchDestinationViewController:UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        getTMapAPISearchDestination(searchStr: searchBar.text!)
    }
}
