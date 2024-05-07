//
//  ParentModeDataPreview.swift
//  YellowLine
//
//  Created by 이종범 on 5/6/24.
//

import SwiftUI

struct ParentModeDataPreview: View {
    let childs: [Child]
    var body: some View {
        List(childs, id: \.id) { child in
            Text(child.name)
        }
    }
}

struct Preview: PreviewProvider {
    static var previews: some View {
        ParentModeDataPreview(childs: ChildsData.load("mock"))
    }
}
