//
//  ContentView.swift
//  LHHouseNoti
//
//  Created by najak on 6/11/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = JSWebViewModel()

    var body: some View {
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
#if false
                    .fullScreenCover(item: $viewModel.presentedDetail) { detail in
                        ExpandWebView(url: detail.url, title: detail.title)
                    }
#endif
                    .navigationDestination(item: $viewModel.presentedDetail) { detail in
                        ExpandWebView(url: detail.url, title: detail.title)
                    }
            }
        }
    }
}
