//
//  RemoteConfigManager.swift
//  LHHouseNoti
//
//  Created by najak on 6/26/26.
//

import FirebaseRemoteConfig
import SwiftUI
import Combine

class RemoteConfigManager: ObservableObject {
    @Published var locationNames: [String] = []
    @Published var panSSNames: [String] = []
    @Published var uppaistpcdNames: [String] = []
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    init() {
        remoteConfig.setDefaults([
            "location_names": ["서울특별시:11", "부산광역시:26", "대구광역시:27", "인천광역시:28", "광주광역시:29", "대전광역시:30", "울산광역시:31", "세종특별자치시:36110", "경기도:41", "강원도:42", "충청북도:43", "충청남도:44", "전라북도:52", "전라남도:46", "경상북도:47", "경상남도:48", "제주특별자치도:50"] as NSObject,
            "panss_names": ["공고중", "접수중", "접수마감", "상담요청", "정정공고중"] as NSObject,
            "uppaistpcd_names": ["분양주택", "토지", "임대주택", "주거복지", "상가", "신혼희망타운"] as NSObject
        ])
        fetchRemoteValues()
    }
    
    func fetchRemoteValues() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 86400           /* 1일 캐시  */
        remoteConfig.configSettings = settings
        
        remoteConfig.fetchAndActivate { [weak self] status, error in
            if let error {
                print("RemoteConfig fetch 실패: \(error)")
                return
            }
            DispatchQueue.main.async {
                let locationJsonString = self?.remoteConfig["location_names"].stringValue ?? "[]"
                if let data = locationJsonString.data(using: .utf8),
                   let names = try? JSONDecoder().decode([String].self, from: data) {
                    self?.locationNames = names
                }
                
                let panSSJsonString = self?.remoteConfig["panss_names"].stringValue ?? "[]"
                if let data = panSSJsonString.data(using: .utf8),
                   let names = try? JSONDecoder().decode([String].self, from: data) {
                    self?.panSSNames = names
                }
                
                let uppaistpcdNamesJsonString = self?.remoteConfig["uppaistpcd_names"].stringValue ?? "[]"
                if let data = uppaistpcdNamesJsonString.data(using: .utf8),
                   let names = try? JSONDecoder().decode([String].self, from: data) {
                    self?.uppaistpcdNames = names
                }
            }
        }
        
    }
}
