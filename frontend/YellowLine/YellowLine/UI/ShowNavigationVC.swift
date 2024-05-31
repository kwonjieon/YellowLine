//
//  ShowNavigationVC.swift
//  YellowLine
//
//  Created by 정성희 on 5/30/24.
//

import UIKit
import TMapSDK
import CoreData
// 보호자가 보는 피보호자의 네비+물체감지 화면
class ShowNavigationVC: UIViewController, TMapViewDelegate {
    // tmap 지도
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    var currentMarker:TMapMarker?
    @IBOutlet weak var mapContainerView: UIView!
    
    // 현재위치
    var locationManger = CLLocationManager()
    var currentLat : Double = 0.0
    var currentLongi : Double = 0.0
    var isReadyLoadMap = false
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var navigationBar: UIView!
    
    @IBOutlet weak var standardLabel: UILabel!
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
        
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)
        mapContainerView.addSubview(self.mapView!)
        
        // 델리게이트 설정
        locationManger.delegate = self
        // 거리 정확도 설정
        locationManger.desiredAccuracy = kCLLocationAccuracyBest
        // 사용자에게 허용 받기 alert 띄우기
        locationManger.requestWhenInUseAuthorization()
        
        // 아이폰 설정에서의 위치 서비스가 켜진 상태라면
        if CLLocationManager.locationServicesEnabled() {
            print("위치 서비스 On 상태")
            locationManger.startUpdatingLocation() //위치 정보 받아오기 시작
            print(locationManger.location?.coordinate)
        } else {
            print("위치 서비스 Off 상태")
        }
        
        // 확대 레벨 기본 설정
        self.mapView?.setZoom(18)
        
        setObjectDetectionView()
        setBackBtn()
        setNameLabel()
        setNavigationBar()
        setLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        isReadyLoadMap = true
        print("isReadyLoadMap : \(isReadyLoadMap)")
        // 현재 위치로 지도 이동
        self.mapView?.setCenter(CLLocationCoordinate2D(latitude: currentLat, longitude: currentLongi))
    }
    
    // 피보호자의 현재위치 마커 표기 업데이트
    func updateCurrentPositionMarker(currentLatitude: CLLocationDegrees, currentLongitude: CLLocationDegrees) {
        // 실시간 위치표기를 위한 기존 현재위치 마커 초기화
        if let existingMarker = currentMarker {
            existingMarker.map = nil
        }

        // 새로운 위치에 마커 생성 및 추가
        currentMarker = TMapMarker(position: CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude))
        currentMarker?.map = mapView
        
        print("마커 업데이트")
    }
    
    func setMapContainerView() {

        mapContainerView.frame = CGRect(x: 0, y: 0, width: 393, height: 403)

        mapContainerView.translatesAutoresizingMaskIntoConstraints = false
        mapContainerView.widthAnchor.constraint(equalToConstant: 393).isActive = true
        mapContainerView.heightAnchor.constraint(equalToConstant: 403).isActive = true
        mapContainerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        mapContainerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 126).isActive = true
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
    
    func setBackBtn() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 33).isActive = true
        backBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80).isActive = true
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
    
    func setLabel() {
        standardLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        standardLabel.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 18)
        standardLabel.textAlignment = .center
        standardLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        destinationLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        destinationLabel.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 18)
        destinationLabel.textAlignment = .center
        destinationLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        destinationLabel.text = "임시도착지데이터"
        
        // 목적지의 글자크기가 바뀌더라도 중앙정렬 유지
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 87).isActive = true
    }
}

extension ShowNavigationVC: CLLocationManagerDelegate {
    // 위치 정보 계속 업데이트 -> 위도 경도 받아옴
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            print("didUpdateLocations")
            if let location = locations.first {
                print("위도: \(location.coordinate.latitude)")
                print("경도: \(location.coordinate.longitude)")
                currentLat = location.coordinate.latitude
                currentLongi = location.coordinate.longitude
            }
            
            if isReadyLoadMap == true {
                // 현재 위치 마커로 표기
                updateCurrentPositionMarker(currentLatitude: currentLat, currentLongitude: currentLongi)
                
                // 현재 위치로 지도 이동
                self.mapView?.setCenter(CLLocationCoordinate2D(latitude: currentLat, longitude: currentLongi))
                
                // 확대 레벨 기본 설정
                self.mapView?.setZoom(18)
            }
        }
        
        // 위도 경도 받아오기 에러
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print(error)
        }
}
