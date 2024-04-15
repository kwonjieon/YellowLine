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
    
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    var locationManager = CLLocationManager()
    var markers:Array<TMapMarker> = []
    let motionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 맵 화면에 로드
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)
        mapContainerView.addSubview(self.mapView!)
        
        
        locationManager.delegate = self  // 델리게이트 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 거리 정확도 설정
        
        // 위치 정보 허용 확인
        checkAuthorizationStatus()
        
        // 방향 감지
        directionDetection()
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
    

    // 현재 위치 주소 가져오기
    func getAddress() {
        print("CLLocationManagerDelegate >> getAddress() ")
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let geocoder = CLGeocoder.init()
        
        let location = self.locationManager.location
        
        if location != nil {
            geocoder.reverseGeocodeLocation(location!) { (placemarks, error) in
                if error != nil {
                    return
                }
                if let placemark = placemarks?.first {
                    var address = ""
                    
                    if let administrativeArea = placemark.administrativeArea {
                        print("== [시/도] administrativeArea : \(administrativeArea)")  //서울특별시, 경기도
                        address = "\(address) \(administrativeArea) "
                    }
                    
                    if let locality = placemark.locality {
                        print("== [도시] locality : \(locality)") //서울시, 성남시, 수원시
                        address = "\(address) \(locality) "
                    }
                    
                    if let subLocality = placemark.subLocality {
                        print("== [추가 도시] subLocality : \(subLocality)") //강남구
                        address = "\(address) \(subLocality) "
                    }
                    
                    if let thoroughfare = placemark.thoroughfare {
                        print("== [상세주소] thoroughfare : \(thoroughfare)") //강남대로106길, 봉은사로2길
                        address = "\(address) \(thoroughfare) "
                    }
                    
                    if let subThoroughfare = placemark.subThoroughfare {
                        print("== [추가 거리 정보] subThoroughfare : \(subThoroughfare)") //272-13
                        address = "\(address) \(subThoroughfare)"
                    }
                    
                    print("CLLocationManagerDelegate >> getAddress() - address : \(address)")  // 서울특별시 광진구 중곡동 272-13
                    
                    //self.txtAddress.text = address
                    print(address)
                }
            }
        }
    }
    
    // 현재 위치 마커 표시
    func currentPositionMarker(currentLongitude: CLLocationDegrees, currentLatitude: CLLocationDegrees) {
        
        let position = self.mapView?.getCenter()
        let marker = TMapMarker(position: CLLocationCoordinate2D(latitude: currentLongitude, longitude: currentLatitude))
        marker.title = "제목없음"
        
        //오류
        marker.map = self.mapView
        self.markers.append(marker)
        
        if let position = position {
            DispatchQueue.main.async{
                
            }
        }
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
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager >> didUpdateLocations 🐥 ")
        
        var longitude = CLLocationDegrees()
        var latitude = CLLocationDegrees()
        
        if let location = locations.first {
            print("위도: \(location.coordinate.latitude)")
            print("경도: \(location.coordinate.longitude)")
            longitude = location.coordinate.latitude
            latitude = location.coordinate.longitude
            
            print("longitude: \(String(longitude))")
            print("latitude: \(String(latitude))")
            //self.txtLongitude.text = String(longitude)
            //self.txtLatitude.text = String(latitude)
        }
        
        //getAddress()
        //locationManager.stopUpdatingLocation()
        
        currentPositionMarker(currentLongitude: longitude, currentLatitude: latitude)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("locationManager >> didChangeAuthorization 🐥 ")
        locationManager.startUpdatingLocation()  //위치 정보 받아오기 start
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager >> didFailWithError 🐥 ")
    }
    
}
