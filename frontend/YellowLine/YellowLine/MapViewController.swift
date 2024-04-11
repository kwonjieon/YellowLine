//
//  MapViewController.swift
//  YellowLine
//
//  Created by 정성희 on 4/11/24.
//

import UIKit
import TMapSDK

// 지도 뷰 로드

class MapViewController: UIViewController, TMapViewDelegate {

    @IBOutlet weak var mapContainerView: UIView!
    @IBAction func backBtn(_ sender: Any) {
        dismiss(animated: true)
    }
    
    var mapView:TMapView?
    let apiKey:String = "YcaUVUHoQr16RxftAbmvGmlYiFY5tkH2iTkvG1V2"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey(apiKey)

        mapContainerView.addSubview(self.mapView!)
    }
}
