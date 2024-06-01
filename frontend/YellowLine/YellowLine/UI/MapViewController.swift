//
//  MapViewController.swift
//  YellowLine
//
//  Created by 정성희 on 4/11/24.
//

import UIKit
import TMapSDK
import CoreLocation
import CoreMotion
import Alamofire
// 지도 뷰 로드
class MapViewController: UIViewController, TMapViewDelegate {
    @IBOutlet weak var objectDetectionView: UIView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBAction func backBtn(_ sender: Any) {
        let nextVC = self.storyboard?.instantiateViewController(identifier: "PopUpStopNavi") as! PopUpStopNavi
        nextVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        nextVC.btn1Text = "취소"
        nextVC.btn2Text = "안내 중단"
        nextVC.titletext = "안내 중단"
        nextVC.descriptionText = "경로 안내를 중단할까요?"
        //webrtc, camera 종료
        self.webRTCManager!.webRTCClient.disconnect()
        self.cameraSession?.stopSession()
        self.present(nextVC, animated: true)
    }

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var standardText: UILabel!
    @IBOutlet weak var destinationText: UILabel!
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var routineInform: UILabel!

    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    var locationManager = CLLocationManager()
    var markers:Array<TMapMarker> = []
    var currentMarker:TMapMarker?
    var polylines:Array<TMapPolyline> = []
    let motionManager = CMMotionManager()
    var polyline:TMapPolyline?
    var LocationPT:Int = 0
    
    // 목적지까지의 네비게이션 안내 정보
    var navigationDataModel : NavigationDataModel?
    
    // 좌/우회전 포함된 기존의 경로안내
    // "편의점에서 우회전 후 55m 직진"
    var navigationList : [String] = []
    
    // 좌/우회전 포함된 목적지 리스트
    var naviDestinationList: [String] = []
    
    // 최종적으로 사용할 좌/우 회전해야 하는 위치 정보 리스트
    var pointerDataList: [LocationData] = []
    
    // 경로 중 좌, 우회전 해야하는 경/위도 리스트
    var naviPointList : [String] = []
    
    // 현재위치
    var longitude:Double = 0.0
    var latitude:Double = 0.0
    
    var startCheckLocation:Bool = false
    
    var searchDestinationViewController: SearchDestinationViewController = .init()
    
    // 선택한 목적지 데이터로, SelectDestinationVC에서 전달받는다
    var destinationName : String?
    var destinationLati : String?
    var destinationLongi : String?
    
    let tts = TTSModelModule()
    var isFirstTTSInform = true
    
    // Object Detection variables
    var webRTCManager: WebRTCManager?
    var cameraSession: CameraSession?
    var protectedId: String?            // 피보호자 아이디 정보가 필요합니다.
    
    //MARK: - Definition Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        // 맵 화면에 로드
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)
        mapContainerView.addSubview(self.mapView!)
        
        routineInform.textColor = .white
        
        locationManager.delegate = self  // 델리게이트 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 거리 정확도 설정
        
        locationManager.distanceFilter = 5.0 // 미터 단위

        
        // 위치 정보 허용 확인
        checkAuthorizationStatus()
        
        // 확대 레벨 기본 설정
        self.mapView?.setZoom(18)
        
        webRTCManager = WebRTCManager(uiView: objectDetectionView, "YLUSER01")
        
        getTMapAPINavigationInform()
        
        setDestinationText()
        
        setNaviBar()
        
    }
    
    // 맵 로드 이후 ui 표시
    override func viewDidAppear(_ animated: Bool) {

        // 맵 로드 이후 마커 표기 시작하게 하는 flag
        startCheckLocation = true
        
        // 현재위치~목적지 경로 루트 표시
        showDestinationRoute()
 
        self.mapView?.setCenter(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        
        //locationManager.startMonitoringSignificantLocationChanges()
        //locationManager.startUpdatingLocation()
    }
    
    //종료 시 
    override func viewDidDisappear(_ animated: Bool) {
        self.viewDidDisappear(true)
        self.webRTCManager!.webRTCClient.disconnect()
        self.cameraSession?.stopSession()
    }
    
    func setObjectDetectionView() {
        objectDetectionView.frame = CGRect(x: 0, y: 0, width: 393, height: 356)
        objectDetectionView.layer.backgroundColor = UIColor(red: 0.851, green: 0.851, blue: 0.851, alpha: 1).cgColor
        objectDetectionView.layer.cornerRadius = 20
        objectDetectionView.translatesAutoresizingMaskIntoConstraints = false
        objectDetectionView.widthAnchor.constraint(equalToConstant: 393).isActive = true
        objectDetectionView.heightAnchor.constraint(equalToConstant: 356).isActive = true
        objectDetectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        objectDetectionView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 496).isActive = true
    }
    
    func setNaviBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: 393, height: 120)
        navigationBar.layer.backgroundColor = UIColor(red: 1, green: 0.841, blue: 0.468, alpha: 1).cgColor
        navigationBar.layer.cornerRadius = 20
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setDestinationText() {
        standardText.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        standardText.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 18)
        standardText.textAlignment = .center
        
        
        destinationText.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        destinationText.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 18)
        destinationText.textAlignment = .center

        destinationText.text = destinationName!
        
        // 목적지의 글자크기가 바뀌더라도 중앙정렬 유지
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 74).isActive = true
         
    }
    
    
    // 경로 초기화
    func clearPolylines() {
        for polyline in self.polylines {
            polyline.map = nil
        }
        self.polylines.removeAll()
    }
    
    // 위치 정보 허용 확인
    func checkAuthorizationStatus() {
        if #available(iOS 17.3.1, *) {
            if locationManager.authorizationStatus == .authorizedAlways
                || locationManager.authorizationStatus == .authorizedWhenInUse {
                print("위치 서비스 On 상태")
                locationManager.startUpdatingLocation() //위치 정보 받아오기 시작 - 사용자의 현재 위치를 보고하는 업데이트 생성을 시작
            } else if locationManager.authorizationStatus == .notDetermined {
                print("위치 서비스 Off 상태")
                locationManager.requestWhenInUseAuthorization()
            } else if locationManager.authorizationStatus == .denied {
                print("위치 서비스 Deny 상태")
            }
            
        } else {
            // Fallback on earlier versions
            if CLLocationManager.locationServicesEnabled() {
                print("위치 서비스 On 상태")
                locationManager.startUpdatingLocation() //위치 정보 받아오기 시작 - 사용자의 현재 위치를 보고하는 업데이트 생성을 시작
                print("LocationViewController >> checkPermission() - \(locationManager.location?.coordinate)")
            } else {
                print("위치 서비스 Off 상태")
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    // 현재 위치 마커 업데이트
    func updateCurrentPositionMarker(currentLatitude: CLLocationDegrees, currentLongitude: CLLocationDegrees) {
        // 실시간 위치표기를 위한 기존 현재위치 마커 초기화
        if let existingMarker = currentMarker {
            existingMarker.map = nil
        }
        // 새로운 위치에 마커 생성 및 추가
        currentMarker = TMapMarker(position: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude))
        currentMarker?.map = mapView
    }
    
    // 지도에 경로 표기
    func showDestinationRoute() {
        clearPolylines()
        
        let pathData = TMapPathData()

        let startPoint = CLLocationCoordinate2D(latitude: latitude, longitude: longitude) // 현재위치

        let endPoint = CLLocationCoordinate2D(latitude: Double(destinationLati!)!, longitude: Double(destinationLongi!)!)
        
        pathData.findPathDataWithType(.PEDESTRIAN_PATH, startPoint: startPoint, endPoint: endPoint) { (result, error)->Void in
            self.polyline = result
    
            DispatchQueue.main.async {
                let marker1 = TMapMarker(position: startPoint)
                marker1.map = self.mapView
                marker1.title = "출발지"
                self.markers.append(marker1)
                
                let marker2 = TMapMarker(position: endPoint)
                marker2.map = self.mapView
                marker2.title = "목적지"
                self.markers.append(marker2)
                
                self.polyline?.map = self.mapView
                self.polylines.append(self.polyline!)
                self.mapView?.fitMapBoundsWithPolylines(self.polylines)
            }
        }
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
            "endX": Double(destinationLongi!)!,
            "endY": Double(destinationLati!)!,
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
                                self.pointerDataList.append(inputData)
                                
                            }
                        case .twoDimensional(let array): break
                        }
                    }
                    var destinationData: LocationData = LocationData()
                    destinationData.latitude = Double(self.destinationLati!)!
                    destinationData.longitude = Double(self.destinationLongi!)!
                    destinationData.name = "finishLine2749"
                    
                    self.pointerDataList.append(destinationData)
                    print("navigationList : \(self.navigationList)")
                    print("naviDestinationList : \(self.naviDestinationList)")
                }catch{
                    print(error)
                }
            })
            dataTask.resume()
        }catch{
            print(error)
        }
    }

    // 네비게이션 경로 범위 내 위치인지 확인
    func checkNavigationDistance() {
        var isOffCourse: Bool = false
        var differenceLati: Double
        var differenceLong: Double
        var leastDifferenceSum: Double
        // 현재 위치와 가장 가까운 경로 포인트
        var proximatePoint: Int = LocationPT
        
        guard let naviPointList = polyline?.path else {
            return
        }
        // 경로 이탈 판단
        // 경로 안내 시작한 직후를 제외하고 판단
        if (LocationPT != 0 && LocationPT != naviPointList.count - 1) {
            //가장 적은값의 오차 비교값 초기 세팅
            leastDifferenceSum = (naviPointList[LocationPT].latitude - latitude) + (naviPointList[LocationPT].longitude - longitude)
            
            for i in LocationPT - 1...LocationPT + 1 {
                differenceLati = naviPointList[i].latitude - latitude
                differenceLong = naviPointList[i].longitude - longitude
                
                // 절대값으로 변환
                if differenceLati < 0 {
                    differenceLati = -differenceLati
                }
                if differenceLong < 0 {
                    differenceLong = -differenceLong
                }
                print ("위도 차이 : \(differenceLati)")
                print ("경도 차이 : \(differenceLong)")
                
                // 경로 이탈 여부 확인
                if  differenceLati < 0.00018 && differenceLong < 0.00018 {
                    // 현재 위치 포인터 수정 여부 확인
                    // 경로포인터-1 보다 지금의 경로포인터가 더 현재와 근접하다면 포인터 현재 위치로 변경
                    if leastDifferenceSum > differenceLati + differenceLong {
                        proximatePoint = i
                        leastDifferenceSum = differenceLati + differenceLong
                    }
                }
                else {
                    isOffCourse = true
                    print("경로 이탈")
                    break
                }
            }
            
            if isOffCourse == false {
                print("경로 범위 이내")
                print("LocationPT: \(LocationPT)")
                LocationPT = proximatePoint
            }
        }
        else {
            LocationPT = 1
        }
    }
    
    //각 pointerData 별로 내 위치와의 거리를 계산하고 하나의 객체라도 거리가 일정 수치 이하라면 경로 안내 출력
    func checkCurrentLoactionRotate() {
        for location in pointerDataList {
            let distance = distanceBetweenPoints(x1: location.latitude, y1: location.longitude, x2: latitude, y2: longitude)
            if distance < 0.00003428 {
                // 목적지에 도착
                if (location.name == "finishLine2749") {
                    print("경로안내 종료")
                    
                    // 음성안내
                    let speechText = location.direction + "에 도착했습니다. 경로안내를 종료합니다."
                    tts.speakText(speechText, 1.0, 0.4, true)
                    
                    // 서버에 피보호자의 경로안내가 끝났다고 status를 업데이트
                    sendChangeToOffline()
                    
                    // 도착 안내 화면으로 이동
                    let nextVC = self.storyboard?.instantiateViewController(identifier: "ArrivalDestinationVC") as! ArrivalDestinationVC
                    nextVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
                    self.present(nextVC, animated: true)
                }
                routineInform.text = location.direction
                
                // 음성안내
                // speakText(내용, 볼륨, 속도, 옵션)
                let speechText = "여기서" + location.direction + "하세요"
                tts.speakText(speechText, 1.0, 0.4, true)
                print("가야하는 방향: \(location.direction)")
            }
        }
    }
    
    // 두 점 사이의 거리
    func distanceBetweenPoints(x1: Double, y1: Double, x2: Double, y2: Double) -> Double {
        let deltaX = x2 - x1
        let deltaY = y2 - y1
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        return distance
    }
    
    // 서버에 피보호자의 경로안내가 끝났다고 status를 업데이트
    func sendChangeToOffline() {
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        let loginURL = "http://43.202.136.75/user/arrival/"
        
        AF.request(loginURL,
                   method: .post,
                   encoding: JSONEncoding(options: []),
                   headers: ["Content-Type":"application/json", "Accept":"application/json"])
            .responseJSON { response in

            /** 서버로부터 받은 데이터 활용 */
            switch response.result {
            case .success(let data):
                break
            case .failure(let error):
                break
            }
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager >> didUpdateLocations 🐥 ")

        if let location = locations.first {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            
            print("현재위도: \(location.coordinate.latitude)")
            print("현재경도: \(location.coordinate.longitude)")
        }
        
        // ui에 그려지는 건 viewDidAppear 이후에 작동
        if startCheckLocation == true {
            // 현재위치 ui 표기 시작
            // 로딩 끝나고 시작할 때
            if (isFirstTTSInform == true) {
                isFirstTTSInform = false
                
                // 음성안내
                let speechText = "음성안내를 시작합니다."
                tts.speakText(speechText, 1.0, 0.4, true)
            }
            //latitudeText.text = String(latitude)
            //longitudeText.text = String(longitude)
            
            // 현재위치 마커 표기
            updateCurrentPositionMarker(currentLatitude: latitude ,currentLongitude: longitude)
            
            // 현재위치 중심 지도 위치 변경
            self.mapView?.setCenter(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            
            // 확대 레벨 기본 설정
            self.mapView?.setZoom(18)

            // 현재 위치에 따른 길안내
            checkCurrentLoactionRotate()
        }
    }
    
    /*
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("locationManager >> didChangeAuthorization 🐥 ")
        locationManager.startUpdatingLocation()  //위치 정보 받아오기 start
    }*/
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager >> didFailWithError 🐥 ")
    }
}

extension MapViewController {
    
}
