//
//  LHHouseNotiApp.swift
//  LHHouseNoti
//
//  Created by najak on 6/11/26.
//

import SwiftUI
import Firebase

@main
struct LHHouseNotiApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationManager.shared)
        }
    }
}
