//
//  WebSocketManager.swift
//  YellowLine
//
//  Created by 이종범 on 4/14/24.
//

import Foundation
import UIKit
class WebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    var imageView: UIImageView?
    
    init(view: UIImageView) {
        self.imageView = view
    }
    
    func connect() {
        guard let url = URL(string: "ws://0.tcp.jp.ngrok.io:15046/yl/ws/") else {return}
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    func send(image: Data) {
        webSocketTask?.send(.data(image)) { error in
            if let error = error {
                print("Error sending image: \(error)")
            } else {
                print("Image sent successfully")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                case .data(let data):
                    let received = UIImage(data: data)
                    DispatchQueue.main.async {
                        self?.imageView?.image = received
                    }
                @unknown default:
                    fatalError()
                }
                
                // Continue receiving messages
                self?.receiveMessage()
            }
        }
    }
    
}
