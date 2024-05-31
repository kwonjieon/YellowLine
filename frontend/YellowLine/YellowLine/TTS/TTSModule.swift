//
//  TTSModule.swift
//  YellowLine
//
//  Created by 이종범 on 5/8/24.
//

import Foundation
import AVFoundation


/*
 speakText (내용, 볼륨, 속도, 옵션)
 
 
 */

class TTSModule {
    let synthesizer = AVSpeechSynthesizer()
    
    func speakText(_ text: String?, _ volume: Float, _ rate: Float, _ avoid: Bool) {
        let audioSession = AVAudioSession() 
        // handle audio session first, before trying to read the text
        do {
            //다른 오디오랑 혼합하려면 option = .mixWithOthers
            //다른 오디오를 피하려면 = .duckOthers
            if avoid == true {
                try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            }else {
                try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
            }
            try audioSession.setActive(false)
        } catch let error {
            print("❓", error.localizedDescription)
        }
        
//        let utterance = AVSpeechUtterance(string: text!)
        let utterance = AVSpeechUtterance(string: "샘플 텍스트입니다")
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = rate
        utterance.volume = volume
        self.synthesizer.stopSpeaking(at: .immediate)
        self.synthesizer.speak(utterance)
    }
    
    // 만약 현재 TTS가 재생중이라면, 즉시종료
    func stopTTS() {
        if self.synthesizer.isSpeaking == true {
            self.synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
