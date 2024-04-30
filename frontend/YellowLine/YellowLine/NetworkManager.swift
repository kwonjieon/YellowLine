//
//  NetworkManager.swift
//  YellowLine
//
//  Created by 이종범 on 4/9/24.
//

import Foundation
import Alamofire
import UIKit
import Combine

class NetworkManager : NSObject{
//    let url: String?
    var urlSession: URLSession?
    var webSocket: URLSessionWebSocketTask?
//    weak var socketDelegate: URLSessionWebSocketDelegate?
    var _url: URL?
    
    init(url: URL?) {
        super.init()
//        self.url = "https://35cf-182-222-253-136.ngrok-free.app/yl/img"
        self._url = url
        self.urlSession = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: OperationQueue())
        self.webSocket = urlSession?.webSocketTask(with: self._url!)
        runUploadImageSession()
    }
    
    func runUploadImages(images: [Data]) -> Deferred<AnyPublisher<UIImage?, Error>> {
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        
        let nowDate = Date()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "H:mm:ss.SSSS"
        let convertedDate = dateFormat.string(from: nowDate)
    
        return Deferred {
            Future<UIImage?, Error> { promise in
                AF.upload(multipartFormData: { multipartFormData in
                    for (idx, image) in images.enumerated() {
                        multipartFormData.append(Data("user1".utf8), withName: "title")
                        multipartFormData.append(image,
                                                 withName: "image",
                                                 fileName: "user1_\(idx)_\(convertedDate).jpeg",
                                                 mimeType: "image/jpeg")
                    }

                }, to: self._url!, method: .post, headers: header)
                .responseData{ response in
                    switch response.result {
                    case .success(let data):
                        let result = UIImage(data: data)
                        promise(.success(result))
                    case .failure(let error):
                        print("Fail...!")
                        promise(.failure(error))
                    }
                }
            }.eraseToAnyPublisher()
        }
    }
    
    func runUploadImage(image: Data?) -> AnyPublisher<UIImage?, Error>{
        let url = "https://35cf-182-222-253-136.ngrok-free.app/yl/img"
        let pub = uploadWithCombine(image: image, url: url)
        return pub
//        subscriptions = pub.sink( receiveCompletion: { completion in
//            switch completion {
//            case .finished:
//                break // 성공적으로 완료
//            case .failure(let error):
//                print(error.localizedDescription) // 오류 처리
//            }
//        }, receiveValue: { [weak self] uploadedImage in
//            DispatchQueue.main.sync {
//                imageView.image = uploadedImage
//            }
//        })
    }
    
    func uploadWithCombine(image: Data?, url stringURL: String) -> AnyPublisher<UIImage?, Error>{
        let header: HTTPHeaders = ["Content-Type" : "multipart/form-data"]
        
        let nowDate = Date()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "H:mm:ss.SSSS"
        let convertedDate = dateFormat.string(from: nowDate)
        
        return Future<UIImage?, Error> { promise in
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(Data("user1".utf8), withName: "title")
                multipartFormData.append(image!,
                                         withName: "image",
                                         fileName: "user1_\(convertedDate).jpeg",
                                         mimeType: "image/jpeg")
            }, to: stringURL, method: .post, headers: header)
            .responseData{ response in
                switch response.result {
                case .success(let data):
                    let result = UIImage(data: data)
                    promise(.success(result))
                case .failure(let error):
                    print("Fail...!")
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    
}


//MARK: -웹소켓
extension NetworkManager : URLSessionWebSocketDelegate{
    //open
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("user1 - Did connected")
        ping()

    }

    //close
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Websocket Closed!")
    }

    func send(images: UIImage) {
        
//        webSocket?.send(<#T##message: URLSessionWebSocketTask.Message##URLSessionWebSocketTask.Message#>, completionHandler: <#T##((any Error)?) -> Void#>)
    }
    
    func ping() {
        webSocket?.sendPing(pongReceiveHandler: { error in
            if let error = error {
                print("Error: \(error)")
            }
        })
    }
    
    func receive() {
        webSocket?.receive(completionHandler: { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Got data: \(data)")
                case .string(let message):
                    print("Got string: \(message)")
                default:
                    print("Unknown type received from WebSocket")
                }
            case .failure(let error):
                print("Receive error: \(error)")
            }
            self?.receive()
        })
    }
    
    func runUploadImageSession() {
        self.webSocket?.resume()
    }
    
    func closeSocket() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
    }
}

extension NetworkManager: URLSessionDelegate{
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        if challenge.previousFailureCount > 0 {
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            print("unknown state. error: \(challenge.error)")
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
