//
//  NotificationService.swift
//  MessageService
//
//  Created by 오션블루 on 7/2/26.
//

import UserNotifications
import RealmSwift

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    private let appGroupID = "group.com.sooyean"
    private let badgeCountKey = "badgeCount"

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        let newBadgeCount = saveToRealm(userInfo: request.content.userInfo)

        bestAttemptContent.badge = NSNumber(value: newBadgeCount)
        
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func saveToRealm(userInfo: [AnyHashable: Any]) -> Int {
        guard let panId = userInfo["panId"] as? String, !panId.isEmpty
        else {
            return 0
        }
        
        let type = userInfo["type"] as? String ?? "new_notice"
        
        do {
            let realm = RealmManager.shared.realm

            let targets = realm.objects(LHHouseInfo.self).filter("PAN_ID == %@", panId)
            var badgeCount: Int = realm.objects(LHHouseInfo.self).filter("isAlarmFlag == true").count
            
            try realm.write {
                if !targets.isEmpty, let existing = targets.first {
                    existing.isAlarmFlag = true
                    existing.isFavorite = existing.isFavorite
                    existing.PAN_SS = userInfo["panSs"] as? String ?? existing.PAN_SS
                    existing.CLSG_DT = userInfo["panClsgDT"] as? String ?? existing.CLSG_DT
                    existing.PAN_NT_ST_DT = userInfo["panNtStDt"] as? String ?? existing.PAN_NT_ST_DT
                    existing.PAN_NM = userInfo["panNm"] as? String ?? existing.PAN_NM
                    existing.AIS_TP_CD_NM = userInfo["aisTpCdNm"] as? String ?? existing.AIS_TP_CD_NM
                    existing.UPP_AIS_TP_CD = userInfo["uppAisTpCd"] as? String ?? existing.UPP_AIS_TP_CD
                    existing.DTL_URL = userInfo["dtlUrl"] as? String ?? existing.DTL_URL
                } else {
                    let info = LHHouseInfo(
                        DTL_URL: userInfo["dtlUrl"] as? String ?? "",
                        isFavorite: false,
                        title: userInfo["panNm"] as? String ?? "", // title 필드는 payload에 없어 PAN_NM으로 대체
                        PAN_ID: panId,
                        CNP_CD_NM: userInfo["cnpCdNm"] as? String ?? "",
                        PAN_SS: userInfo["panSs"] as? String ?? "",
                        PAN_NM: userInfo["panNm"] as? String ?? "",
                        AIS_TP_CD_NM: userInfo["aisTpCdNm"] as? String ?? "",
                        PAN_NT_ST_DT: userInfo["panNtStDt"] as? String ?? "",
                        CLSG_DT: userInfo["panClsgDT"] as? String ?? "",
                        isAlarmFlag: true
                    )
                    info.UPP_AIS_TP_CD = userInfo["uppAisTpCd"] as? String ?? ""
                    realm.add(info)
                    badgeCount = realm.objects(LHHouseInfo.self).filter("isAlarmFlag == true").count
                    
                }
                return badgeCount
            }
            print("✅ Realm 저장 완료 (\(type)): \(panId)")
        } catch {
            print("❌ Realm write error in extension: \(error)")
            return 0
        }
        return 0
    }
}
