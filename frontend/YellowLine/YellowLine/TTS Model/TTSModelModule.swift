//
//  TTSModelModule.swift
//  YellowLine
//
//  Created by 정성희 on 5/28/24.
//

import Foundation
import AVFoundation


/*
 speakText (내용, 볼륨, 속도, 옵션)
 */

class TTSModelModule {
    static let ttsModule = TTSModelModule()
    var ttsSemaphore = DispatchSemaphore(value: 2)
    var objectCounts = 0
    let synthesizer = AVSpeechSynthesizer()
    private var ttsQueue : [String] = []
    private var channels: (navi: Bool, camera: Bool) = (false, false)
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
        guard let text = text else {return}
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = rate
        utterance.volume = volume
        self.synthesizer.stopSpeaking(at: .immediate)
        self.synthesizer.speak(utterance)
    }
    
    func speakTTS(text: String) {
        if channels.navi || !synthesizer.isSpeaking {
            // handle audio session first, before trying to read the text
            do {
                //다른 오디오랑 혼합하려면 option = .mixWithOthers
                //다른 오디오를 피하려면 = .duckOthers
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error {
                print("❓", error.localizedDescription)
            }
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            utterance.rate = 0.4
            utterance.volume = 10
            self.synthesizer.stopSpeaking(at: .word)
            self.synthesizer.speak(utterance)
        }
        
    }
    
    // type true = navi ,  = camera
    func processTTS(type: Bool, text: String) {
        if type {
            channels.navi = true
            speakTTS(text: text)
            channels.navi = false
        } else {
            guard objectCounts >= 5 else { return }
            self.ttsQueue.append(text)
            speakTTS(text: text)
        }
    }
    
    func checkTtsQueue() {
        if !ttsQueue.isEmpty {
            guard let text = ttsQueue.first else { return }
            speakTTS(text: text)
        }
    }

    
    // 만약 현재 TTS가 재생중이라면, 즉시종료
    func stopTTS() {
        if self.synthesizer.isSpeaking == true {
            self.synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
