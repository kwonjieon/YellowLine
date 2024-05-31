//
//  TTSModelController.swift
//  YellowLine
//
//  Created by 정성희 on 5/28/24.
//

import Foundation
class TTSController{
    
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
