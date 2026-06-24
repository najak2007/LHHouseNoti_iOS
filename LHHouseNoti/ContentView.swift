//
//  ContentView.swift
//  LHHouseNoti
//
//  Created by najak on 6/11/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = JSWebViewModel()
    @State private var tabIndex: Int = 0

    var body: some View {
        TabView(selection: $tabIndex) {
            Tab("홈", systemImage: "house", value: 0) {
                NavigationStack {
                    ZStack {
                        Color.white
                            .ignoresSafeArea() // 노치/홈 인디케이터 영역까지 흰색으로 채움
                        
                        JSWebView(viewModel: viewModel, url: URL(string: "https://lhhousenoti.web.app")!)
                            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FCMTokenReceived"))) { notification in
                                if let token = notification.userInfo?["token"] as? String {
                                    viewModel.updatePushToken(token)
                                }
                            }
                            .navigationDestination(item: $viewModel.pushedViewDetail) { lhhouseModel in
                                if URL(string: lhhouseModel.DTL_URL) != nil {
                                    ExpandWebView(lhhouseModel: lhhouseModel)
                                        .toolbar(.hidden, for: .tabBar)
                                }
                            }
                    }
                }
            }
            Tab("즐겨찾기", systemImage: "star.circle", value: 1) {
                NavigationStack {
                    FavoritesView(viewModel: viewModel)
                        .navigationDestination(item: $viewModel.pushedViewDetail) { lhhouseModel in
                        if URL(string: lhhouseModel.DTL_URL) != nil {
                            ExpandWebView(lhhouseModel: lhhouseModel)
                            .toolbar(.hidden, for: .tabBar) // 푸시될 때 하단 탭 숨김
                        }
                    }
                }
            }
        }
    }
}
