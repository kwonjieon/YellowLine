//
//  ClientModeView.swift
//  YellowLine
//
//  Created by 이종범 on 5/6/24.
//

import SwiftUI

struct ClientModeView: View {
    // -1: not selected, 0 : 길찾기, 1 : 위험한 물체 탐색
    @State var clientMode = -1
    @State var boolmode = false
    var body: some View {
        NavigationView {
            ZStack() {
                ZStack() {
                    VStack(spacing: 0) {
                        Rectangle()
                        .foregroundColor(.clear)
                        .background(Image("ic-glasses"))
                        .offset(y: 150)
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 393, height: 852)
                            .background(Image("ic-waveline"))
                    }
//                    .frame(width: 393)
//                    .offset(x: -11.50, y: 0)
                    Text("옐로라인")
                        .font(Font.custom("AppleSDGothicNeoH00", size: 32))
                        .lineSpacing(22)
                        .foregroundColor(.white)
                        .offset(x: 0, y: -198)
                } //ZStack
                
                ZStack() {
                    NavigationLink(destination: NaviCameraView()) {
                        ZStack() {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 356, height: 149)
                                .background(.white)
                                .offset(x: 0, y: 0)
                                .shadow(
                                    color: Color(red: 1, green: 1, blue: 1, opacity: 0.25), radius: 25
                                )
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 99.41, height: 114.02)
                                .background(Image("ic-pointer"))
                                .offset(x: 128.29, y: -17.49)
                            Text("길찾기")
                                .font(Font.custom("AppleSDGothicNeoB00", size: 24))
                                .lineSpacing(22)
                                .foregroundColor(.black)
                                .offset(x: 5.50, y: -48)
                            Text("보행시 위험한 물체가 있는지 확인하면서\n음성 안내와 함께 길을 안내해드려요.")
                                .font(Font.custom("AppleSDGothicNeoL00", size: 21))
                                .lineSpacing(24)
                                .foregroundColor(.black)
                                .offset(x: -1, y: 8)
                        }
                        .background(Color("AccentColor"))
                        .clipShape(.rect(cornerRadius: 20))
                        .offset(x: 0, y: -21.50)
                    }
                    
                } //ZStack
                .offset(x: 0.50, y: 153)
                
                ZStack() {
                    NavigationLink(destination: CameraOnlyView()) {
                        ZStack() {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 356, height: 149)
                                .background(.white)
                                .offset(x: 0, y: 0)
                                .shadow(
                                    color: Color(red: 1, green: 1, blue: 1, opacity: 0.25), radius: 25
                                )
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 89, height: 115.46)
                                .background(Image("ic-exclamark"))
                                .offset(x: -133.50, y: 16.77)
                            
                            Text("위험한 물체 탐색")
                                .font(Font.custom("AppleSDGothicNeoB00", size: 24))
                                .lineSpacing(22)
                                .foregroundColor(.black)
                            
                                .offset(x: 0, y: -48)
                            Text("보행시 위험한 물체가 있는지\n확인해 드려요.")
                                .font(Font.custom("AppleSDGothicNeoL00", size: 21))
                                .lineSpacing(22)
                                .foregroundColor(.black)
                                .offset(x: -1, y: 8)
                        }
                        .background(Color("AccentColor"))
                        .clipShape(.rect(cornerRadius: 20))
                        .offset(x: 0, y: -21.50)
                    }//ZStack
                    .offset(x: 0.50, y: 323)
                }
                    
                
            } // ZStack
//            .frame(width: 393, height: 852)
            .background(Color("BackgroundColor"))
            
        } //NavigationView
        
    }
}

#Preview {
    ClientModeView()
}

/*
 https://sarunw.com/posts/swiftui-view-as-uiviewcontroller/ swiftui를 이용한 controller 사용법
 
 */
