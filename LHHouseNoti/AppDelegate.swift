//
//  AppDelegate.swift
//  LHHouseNoti
//
//  Created by najak on 6/11/26.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. 앱 시작 시 사용자에게 알림 권한 요청
        requestNotificationAuthorization(application: application)
        
        return true
    }
    
    // 2. 푸시 등록 성공 시 호출 (디바이스 토큰 수신)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Data 타입의 토큰을 String 형태로 변환
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            
        // 💡 콘솔에서 토큰을 확인하거나 서버(APNs/Firebase 등)로 전송하세요.
        print("✅ 성공: 푸시 디바이스 토큰 -> \(tokenString)")
    }
        
    // 3. 푸시 등록 실패 시 호출
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ 실패: 원격 알림 등록에 실패했습니다: \(error.localizedDescription)")
    }
        
    // 4. 앱이 포그라운드(실행 중) 상태일 때 푸시가 오면 처리하는 옵션 (선택 사항)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 켜져 있을 때도 배너와 소리가 나도록 설정
        completionHandler([.banner, .list, .sound])
    }

    // MARK: - 알림 권한 요청 메서드
    private func requestNotificationAuthorization(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        
        // 포그라운드 알림 처리를 위해 델리게이트 임명
        center.delegate = self
            
        center.requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
            if let error = error {
                print("❌ 알림 권한 요청 중 에러 발생: \(error.localizedDescription)")
                return
            }
                
            if granted {
                print("✅ 알림 권한이 허용되었습니다.")
                // 권한이 허용되면 메인 스레드에서 APNs에 디바이스 등록 요청
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("🚨 사용자가 알림 권한을 거부했습니다.")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {}
