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

// 지도 뷰 로드



class MapViewController: UIViewController, TMapViewDelegate {
    
    @IBOutlet weak var mapContainerView: UIView!
    @IBAction func backBtn(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBOutlet weak var offTrackText: UILabel!
    @IBOutlet weak var latitudeText: UILabel!
    @IBOutlet weak var longitudeText: UILabel!
    @IBOutlet weak var latitudeGapLabel: UILabel!
    @IBOutlet weak var longitudeGapLabel: UILabel!
    
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    var locationManager = CLLocationManager()
    var markers:Array<TMapMarker> = []
    var currentMarker:TMapMarker?
    var polylines:Array<TMapPolyline> = []
    let motionManager = CMMotionManager()
    var polyline:TMapPolyline?
    var LocationPT:Int = 0
    
    var longitude:Double = 0.0
    var latitude:Double = 0.0
    
    
    var startCheckLocation:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 맵 화면에 로드
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)
        mapContainerView.addSubview(self.mapView!)
        
        
        locationManager.delegate = self  // 델리게이트 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 거리 정확도 설정
        
        locationManager.distanceFilter = 5.0 // 미터 단위

        
        // 위치 정보 허용 확인
        checkAuthorizationStatus()
        
        // 확대 레벨 기본 설정
        self.mapView?.setZoom(18)
        
        // 방향 감지
        //directionDetection()
        
        // GPS 위치 탐지 시작
        //locationManager.startUpdatingLocation()
        
        
    }
    
    // 맵 로드 이후 ui 표시
    override func viewDidAppear(_ animated: Bool) {
        // 맵 로드 이후 마커 표기 시작하게 하는 flag
        startCheckLocation = true
        
        // 현재위치~목적지 경로 루트 표시
        showDestinationRoute()
    
        //
        //updateCurrentPositionMarker(currentLatitude: latitude ,currentLongitude: longitude)
        self.mapView?.setCenter(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        
    }
    
    // 마커 초기화
    func clearMarkers() {
        for marker in self.markers {
            marker.map = nil
        }
        self.markers.removeAll()
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
    
    // 디바이스 방향 감지
    func directionDetection() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2 // 업데이트 간격 설정 (초 단위)
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (data, error) in
                guard let data = data else { return }
                
                // 디바이스의 방향 데이터 추출
                let attitude = data.attitude
                
                // 방향 데이터를 사용하여 각도를 계산
                let pitch = attitude.pitch * 180.0 / Double.pi
                let roll = attitude.roll * 180.0 / Double.pi
                let yaw = attitude.yaw * 180.0 / Double.pi
                
                // 화면에 방향 데이터 출력
                print("Pitch: \(pitch) degrees")
                print("Roll: \(roll) degrees")
                print("Yaw: \(yaw) degrees")
            }
        } else {
            print("Device motion is not available")
        }
    }
    
    // 지도에 경로 표기
    func showDestinationRoute() {
        clearPolylines()
        
        let pathData = TMapPathData()
        //let startPoint = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let startPoint = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let endPoint = CLLocationCoordinate2D(latitude: 37.55093876107976, longitude: 127.07363779704937)
        pathData.findPathDataWithType(.PEDESTRIAN_PATH, startPoint: startPoint, endPoint: endPoint) { (result, error)->Void in
            self.polyline = result
            
            print("line: \(self.polyline?.path)")
            
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
                
                latitudeGapLabel.text = String(differenceLati)
                longitudeGapLabel.text = String(differenceLong)
                
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
                    DispatchQueue.main.async {
                        self.offTrackText.text = "경로 이탈!"
                    }
                    break
                }
            }
            
            if isOffCourse == false {
                print("경로 범위 이내")
                DispatchQueue.main.async {
                    self.offTrackText.text = "경로 범위 이내!"
                }
                print("LocationPT: \(LocationPT)")
                LocationPT = proximatePoint
            }
        }
        else {
            LocationPT = 1
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager >> didUpdateLocations 🐥 ")
        
        latitude = CLLocationDegrees()
        longitude = CLLocationDegrees()

        if let location = locations.first {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            
            print("위도: \(location.coordinate.latitude)")
            print("경도: \(location.coordinate.longitude)")
        }
        
        // ui에 그려지는 건 viewDidAppear 이후에 작동
        if startCheckLocation == true {
            latitudeText.text = String(latitude)
            longitudeText.text = String(longitude)
            
            // 현재위치 마커 표기
            updateCurrentPositionMarker(currentLatitude: latitude ,currentLongitude: longitude)
            
            // 현재위치 중심 지도 위치 변경
            self.mapView?.setCenter(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            
            // 확대 레벨 기본 설정
            self.mapView?.setZoom(18)
            
            // 경로 안내
            checkNavigationDistance()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("locationManager >> didChangeAuthorization 🐥 ")
        locationManager.startUpdatingLocation()  //위치 정보 받아오기 start
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager >> didFailWithError 🐥 ")
    }
}

