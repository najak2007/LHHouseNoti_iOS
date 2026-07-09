//
//  NotificationManager.swift
//  LHHouseNoti
//
//  Created by najak on 6/16/26.
//

import Foundation
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import Combine
import FirebaseRemoteConfig

class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published var fcmToken: String = ""
    
    private override init() {}

    // 현재 FCM 토큰 즉시 가져오기
    func fetchCurrentToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("FCM 토큰 조회 실패: \(error.localizedDescription)")
                return
            }
            guard let token = token else { return }
            DispatchQueue.main.async {
                self.fcmToken = token
            }
            print("현재 FCM 토큰: \(token)")
            self.saveTokenToFirestore(token)
        }
    }
}

// MARK: - FCM 토큰 관리
extension NotificationManager: MessagingDelegate {

    // 토큰 자동 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        DispatchQueue.main.async {
            self.fcmToken = token
        }

        print("FCM 토큰 갱신: \(token)")

        // Firestore에 저장 (서버 없이 Firebase만 사용하는 경우)
        saveTokenToFirestore(token)
        
        resubscribeToSavedTopics()
    }

    private func saveTokenToFirestore(_ token: String) {
        let dataDict: [String: String] = ["token": token]
        NotificationCenter.default.post(
            name: NSNotification.Name("FCMTokenReceived"),
            object: nil,
            userInfo: dataDict
        )
        guard let userId = Auth.auth().currentUser?.uid else {
            print("로그인 유저 없음 → 토큰 저장 생략")
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .setData( [
                "fcmToken": token,
                "uuid": DeviceIdentifier.shared.getDeviceUUID(),
                "platform": "i"
            ], merge: true) { error in
                if let error = error {
                    print("Firestore 토큰 저장 실패: \(error.localizedDescription)")
                } else {
                    print("Firestore 토큰 저장 완료 ✅")
                }
            }
    }
    
    private func resubscribeToSavedTopics() {
        fetchUserRegion() { cnpCdNmList in
            guard let cnpCdNmList = cnpCdNmList,
                  cnpCdNmList.isEmpty == false
            else {
                return
            }
            self.fetchLocationNames() { locations in
                for cnpCdNm in cnpCdNmList {
                    if let matched = locations.first(where: { $0.name == cnpCdNm}), matched.code.isEmpty == false {
                        
                        Messaging.messaging().subscribe(toTopic: "CNP_\(matched.code)") { error in
                            if let error = error {
                                print("❌ 토픽 재구독 실패 (CNP_\(matched.code)):", error.localizedDescription)
                            } else {
                                print("✅ 토픽 재구독 성공:", "(CNP_\(matched.code))")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchLocationNames(completion: @escaping([(name: String, code: String)]) -> Void) {
        let remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1시간
        remoteConfig.configSettings = settings

        // 네트워크 지연/실패 대비 기본값
        remoteConfig.setDefaults([
            "location_names": """
            ["서울특별시:11", "부산광역시:26", "대구광역시:27", "인천광역시:28",
             "광주광역시:29", "대전광역시:30", "울산광역시:31", "세종특별자치시:36110",
             "경기도:41", "강원도:42", "충청북도:43", "충청남도:44",
             "전라북도:52", "전라남도:46", "경상북도:47", "경상남도:48",
             "제주특별자치도:50"]
            """ as NSObject
        ])

        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                print("❌ Remote Config fetch 실패:", error.localizedDescription)
                return
            }

            let rawString = remoteConfig.configValue(forKey: "location_names").stringValue
            self.parseAndStoreLocationNames(rawString, completion: completion)
        }
    }

    private func parseAndStoreLocationNames(_ raw: String, completion: @escaping([(name: String, code: String)]) -> Void) {
        guard let data = raw.data(using: .utf8) else { return }

        do {
            // ["서울특별시:11", "부산광역시:26", ...] 형태의 JSON 배열 파싱
            let items = try JSONDecoder().decode([String].self, from: data)

            let locations: [(name: String, code: String)] = items.compactMap { item in
                let parts = item.split(separator: ":", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                return (name: parts[0], code: parts[1])
            }
            print("✅ location_names 파싱 완료:", locations)
            completion(locations)
        } catch {
            print("❌ location_names 파싱 실패:", error.localizedDescription)
        }
    }
    
    func fetchUserRegion(completion: @escaping ([String]?) -> Void) {
        Firestore.firestore()
            .collection("users")
            .document(DeviceIdentifier.shared.getDeviceUUID())
            .getDocument { snapshot, error in
                if error != nil {
                    completion(nil)
                    return
                }
                
                guard let data = snapshot?.data()
                else {
                    completion(nil)
                    return
                }
                let cnpCdNmList = data["CNP_CD_NM"] as? [String] ?? []
                print("✅ 사용자 지역 목록:", cnpCdNmList)
                completion(cnpCdNmList)
            }
    }
}

// MARK: - 알림 수신 처리
extension NotificationManager: UNUserNotificationCenterDelegate {

    // 포그라운드 알림 수신
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 탭 시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        PendingPushNavigation.payload = userInfo
        
        NotificationCenter.default.post(
            name: NSNotification.Name(Config.PUSH_NOTIFICATION_SELECTED_ID),
            object: nil,
            userInfo: userInfo
        )


        print("알림 탭: \(userInfo)")
        completionHandler()
    }
}
