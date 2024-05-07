//
//  ParentModeView.swift
//  YellowLine
//
//  Created by 이종범 on 5/6/24.
//
import SwiftUI

struct Child: Codable{
    var id: String
    var name: String
    var location: String
    var state: Int
}

struct ParentModeView: View {
//    @State var items: [Child] = []
//    var child: Child

    var body: some View {
        Text("Hi")
    }
}

#Preview {
//    ParentModeView(child: childlist[0])
    ParentModeView()
}
