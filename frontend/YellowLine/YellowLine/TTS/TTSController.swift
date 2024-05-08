//
//  TTSController.swift
//  YellowLine
//
//  Created by 이종범 on 5/8/24.
//

import Foundation
import UIKit

class TTSController : UIViewController{
    
    @IBOutlet var btn: UIButton!
    
    let tts = TTSModule()

//    let synthesizer = AVSpeechSynthesizer()
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Hello")
    }
    
    @IBAction func btnaction(_ sender: Any) {
        tts.speakText("안녕하세요", 1.0, 0.4, true)
    }
    
}
