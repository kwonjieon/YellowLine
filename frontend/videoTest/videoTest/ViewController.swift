//
//  ViewController.swift
//  videoTest
//
//  Created by 정성희 on 3/25/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: captureDevice)
            
            photoOutput = AVCapturePhotoOutput()
            
            captureSession.addInput(cameraInput)
            captureSession.sessionPreset = .photo
            captureSession.addOutput(photoOutput)
            captureSession.commitConfiguration()
        } catch {
            print(error)
        }
        
        //preview
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        DispatchQueue.main.async {
            self.videoPreviewLayer.frame = self.previewView.bounds
        }
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        self.previewView.layer.addSublayer(videoPreviewLayer)
        
        captureSession.startRunning()
        
    }
    /*
    @IBAction func takePhoto(_ sender: Any) {
        photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self as AVCapturePhotoCaptureDelegate)
    }
    */
    /*
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)
        // 이미지뷰에 이미지 설정
    }
     */
}

