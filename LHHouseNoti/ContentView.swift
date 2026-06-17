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
        JSWebView(viewModel: viewModel, url: URL(string: "https://lhhousenoti.web.app")!)
            .ignoresSafeArea()
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FCMTokenReceived"))) { notification in
                if let token = notification.userInfo?["token"] as? String {
                    viewModel.updatePushToken(token)
                }
            }
    }
}
