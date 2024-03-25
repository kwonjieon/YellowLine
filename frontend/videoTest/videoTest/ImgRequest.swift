//
//  ImgRequest.swift
//  videoTest
//
//  Created by 이종범 on 3/25/24.
//


struct Response:Codable {
    let success: Bool
    let result: String
    let message: String
}

func requestPost(url: String, method: String, param: [String: Any], completionHandler: @escaping (Bool, Any) -> Void) {
    
}
