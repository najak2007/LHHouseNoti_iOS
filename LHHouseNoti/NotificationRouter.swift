//
//  NotificationRouter.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 7/8/26.
//

import Foundation
import Combine

final class NotificationRouter: ObservableObject {
    static let shared = NotificationRouter()
    
    @Published var pendingDetailURL: URL?
    @Published var selectedTab: Int = 0
    
    private init() {}
    
    func route(from userInfo: [AnyHashable: Any]) {
        guard let urlString = userInfo["detailUrl"] as? String,
              let url = URL(string: urlString) else {
            return
        }
        
        if let tabString = userInfo["tab"] as? String,
           let tab = Int(tabString) {
            selectedTab = tab
        }
        
        pendingDetailURL = url
    }
}
