//
//  JSWebViewModel.swift
//  LHHouseNoti
//
//  Created by najak on 6/12/26.
//

import SwiftUI
import WebKit
import Combine
import RealmSwift
internal import Realm
import FirebaseAnalytics
import FirebaseMessaging


var expandWebViewCloseHandler = PassthroughSubject<Bool, Never>()
var lhhouseAlarmYNHandler = PassthroughSubject<[String: Any], Never>()

class JSWebViewModel: ObservableObject {
    @Published var deviceUUID: String = ""
    @Published var pushToken: String = ""
    @Published var osType: String = "i"              // 0 : iOS, 1 : Android, 2 : 기타
    @Published var receivedMessage: String = ""
    
    @Published var presentedDetail: LHHouseFileDownModel? = nil
    @Published var pushedViewDetail: LHHouseModel? = nil
    
    @Published var lhhouseFavorites: [LHHouseInfo] = []
    @Published var lhhouseAlarms: [LHHouseInfo] = []
    @Published var usersAlarmiInfo: [String: Any] = [:]
    
    private var notificationToken: NotificationToken?  // 추가
    
    weak var webView: WKWebView?
    
    private var realm: Realm?
    
    init() {
        deviceUUID = DeviceIdentifier.shared.getDeviceUUID()
        realm = RealmManager.shared.realm
        
        fetchLHHouseData()
        
        Task {
            _ = try await fetchUserFields()
        }
    }
    
    // React로 UUID + Token + OSType
    func sendDeviceInfoToWeb() {
        let token = pushToken.isEmpty ? "" : pushToken
        
        guard let uuidData = try? JSONEncoder().encode(deviceUUID),
              let tokenData = try? JSONEncoder().encode(token),
              let osTypeData = try? JSONEncoder().encode(osType),
              let modelNameData = try? JSONEncoder().encode(UIDevice.current.model),
              let detailModelNameData = try? JSONEncoder().encode(UIDevice.current.detailedModelName),
              let uuidJSON = String(data: uuidData, encoding: .utf8),
              let tokenJSON = String(data: tokenData, encoding: .utf8),
              let osTypeJSON = String(data: osTypeData, encoding: .utf8),
              let modelNameJSON = String(data: modelNameData, encoding: .utf8),
              let detailModelNameJSON = String(data: detailModelNameData, encoding: .utf8)
                
        else { return }
        
        let script = "if(window.receiveDeviceInfo) { window.receiveDeviceInfo(\(uuidJSON), \(tokenJSON), \(osTypeJSON), \(modelNameJSON), \(detailModelNameJSON)) }"

        webView?.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("JS 호출 에러: \(error)")
            }
        }
    }
    
    func updatePushToken(_ token: String) {
        pushToken = token
        sendDeviceInfoToWeb()
    }
    
    func fetchLHHouseData() {
        guard let realm = realm else { return }

        let sortedResults = realm.objects(LHHouseInfo.self)
            .sorted(byKeyPath: "registerDate", ascending: false)

        // 기존 Array(...) 스냅샷 대신 observe로 변경 구독
        notificationToken = sortedResults.observe { [weak self] changes in
            guard let self else { return }
            switch changes {
            case .initial(let results), .update(let results, _, _, _):
                DispatchQueue.main.async {
                    self.lhhouseFavorites = Array(results).filter { $0.isFavorite }
                    self.lhhouseAlarms = Array(results).filter { $0.isAlarmFlag }
                    UNUserNotificationCenter.current().setBadgeCount(self.lhhouseAlarms.count)
                }
            case .error(let error):
                print("Realm observe 에러: \(error)")
            }
        }
    }

    deinit {
        notificationToken?.invalidate()  // 추가
    }
    
    func setLHHouseAlarmReadStatus(_ lhHouseModel: LHHouseModel, isRead: Bool = true, completion: @escaping() -> Void) {
        guard let realm = self.realm
        else {
            return
        }
        
        let targets = realm.objects(LHHouseInfo.self).filter("PAN_ID == %@", lhHouseModel.PAN_ID)
        do {
            try realm.write {
                if let targetInfo = targets.first {
                    let newHouseInfo = LHHouseInfo(lhHouseModel, isFavorite: targetInfo.isFavorite, isAlarmFlag: isRead)
                    realm.add(newHouseInfo, update: .all)
                }
            }
        } catch {
            print("error: \(error)")
        }
        fetchLHHouseData()
        completion()
    }
    
    func fetchLHHouseForPanId(userInfo: [AnyHashable: Any], completion: @escaping(LHHouseModel?) -> Void) {
        guard let panId = userInfo["panId"] as? String, !panId.isEmpty
        else {
            completion(nil)
            return
        }
        
        if let lhHouseModel = realm?.objects(LHHouseInfo.self).filter("PAN_ID == %@", panId).first?.lhhouseModel {
            completion(lhHouseModel)
            return
        }
        
        do {
            if let realm = self.realm {
                try realm.write {
                    let lhHouseInfo = LHHouseInfo(
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
                    lhHouseInfo.UPP_AIS_TP_CD = userInfo["uppAisTpCd"] as? String ?? ""
                    realm.add(lhHouseInfo)
                    completion(lhHouseInfo.lhhouseModel)
                }
            }
        } catch {
            return completion(nil)
        }
    }
    
    func saveLHHouseFavorite(_ lhHouseModel: LHHouseModel, completion: @escaping(Bool) -> Void) {
        guard let realm = self.realm else {
            completion(false)
            return
        }
        // Realm 전용 쿼리로 찾기 (NSPredicate 또는 체이닝)
        let targets = realm.objects(LHHouseInfo.self).filter("PAN_ID == %@", lhHouseModel.PAN_ID)
        var isRegister: Bool = true
        
        do {
            try realm.write {
                if targets.isEmpty {
                    let newHouseInfo = LHHouseInfo(lhHouseModel, isFavorite: true)
                    realm.add(newHouseInfo)
                    isRegister = true
                } else {
                    if let targetInfo = targets.first {
                        isRegister = !targetInfo.isFavorite
                        let newHouseInfo = LHHouseInfo(lhHouseModel, isFavorite: isRegister, isAlarmFlag: targetInfo.isAlarmFlag)
                        realm.add(newHouseInfo, update: .all)
                    } else {
                        isRegister = false
                    }
                }
            }
        } catch {
            print("Realm 에러: \(error)")
            completion(false)
            return
        }
        
        fetchLHHouseData()
        completion(isRegister)
    }
    
    func fetchLHHouseItem(_ lhHouseModel: LHHouseModel, completion: @escaping(Bool) -> Void) {
        guard let realm = realm else { return }
        let results = realm.objects(LHHouseInfo.self)
        let lhhouseInfoArr = results.filter( { $0.PAN_ID == lhHouseModel.PAN_ID } )
        
        guard let lhhouseInfo = lhhouseInfoArr.first else {
            completion(false)
            return
        }
        
        completion(lhhouseInfoArr.isEmpty == false && lhhouseInfo.isFavorite == true)
    }
    
    func setUsersNotices(_ isON: Bool, _ fieldKey: String, _ fieldItem: String) async throws {
        if isON {
            try await addUsersNotices(fieldKey, fieldItem)
        } else {
            try await removeUsersNotices(fieldKey, fieldItem)
        }
        lhhouseAlarmYNHandler.send([
            "isON": isON,
            "fieldKey": fieldItem
        ])
    }
    
    
    private func addUsersNotices(_ fieldKey: String, _ fieldItem: String) async throws {
        // 1. 기존 users 컬랙션 값 가져오기
        guard var usersNotiDic = try await fetchUserFields()
        else {
            return
        }
        
        // 2. users 컬랙션에 저장된 fieldKey에 맞는 배열 가져오기
        var editFielsList: [String] = usersNotiDic[fieldKey] as? [String] ?? []
        
        // 3. 중복 체크 후 추가
        guard !editFielsList.contains(fieldItem.getKey)
        else {
            print("⚠️ 이미 등록된 \(fieldKey): \(fieldItem.getKey)")
            return
        }
        
        editFielsList.append(fieldItem.getKey)
        usersNotiDic.updateValue(editFielsList, forKey: fieldKey)
        
        // 4. 저장
        try await FirestoreRESTClient.shared.setDocument(
            collection: "users",
            documentId: deviceUUID,
            fields: usersNotiDic)
        
        let topicName = "\(fieldKey.getFirstValue)_\(fieldItem.getValue)"
            
        do {
            // 비동기 대안 함수 호출 (try await 사용)
            try await Messaging.messaging().subscribe(toTopic: topicName)
            print("\(topicName) 알림 구독 완료!")
        } catch {
            print("구독 실패 오류 발생: \(error.localizedDescription)")
        }
        
        usersAlarmiInfo = usersNotiDic
        print("✅ CNP_CD_NM 추가 완료: \(usersNotiDic)")
    }
    
    private func removeUsersNotices(_ fieldKey: String, _ fieldItem: String) async throws {
        // 1. 기존 users 컬랙션 값 가져오기
        guard var usersNotiDic = try await fetchUserFields()
        else {
            return
        }

        // 2. users 컬랙션에 저장된 fieldKey에 맞는 배열 가져오기
        var editFielsList: [String] = usersNotiDic[fieldKey] as? [String] ?? []
       
        // 3. 해당 항목 제거
        editFielsList.removeAll { $0 == fieldItem.getKey }

        if editFielsList.isEmpty {
            usersNotiDic.removeValue(forKey: fieldKey)
        } else {
            usersNotiDic.updateValue(editFielsList, forKey: fieldKey)
        }
        
        if usersNotiDic.isEmpty {
            try await FirestoreRESTClient.shared.deleteDocument(
                collection: "users",
                documentId: deviceUUID
            )
            print("✅ 마지막 항목 삭제 → 문서 제거")
        } else {
            try await FirestoreRESTClient.shared.setDocument(
                collection: "users",
                documentId: deviceUUID,
                fields: usersNotiDic
            )
            print("✅ Users Notices Info 삭제 완료: \(usersNotiDic)")
        }
        
        let topicName = "\(fieldKey.getFirstValue)_\(fieldItem.getValue)"
            
        do {
            // 비동기 대안 함수 호출 (try await 사용)
            try await Messaging.messaging().unsubscribe(fromTopic: topicName)
            print("\(topicName) 알림 구독 완료!")
        } catch {
            print("구독 실패 오류 발생: \(error.localizedDescription)")
        }
        
        usersAlarmiInfo = usersNotiDic
    }
    
    private func fetchUserFields() async throws -> [String: Any]?  {
        do {
            let doc = try await FirestoreRESTClient.shared.getDocument(
                collection: "users",
                documentId: deviceUUID
            )
            usersAlarmiInfo = doc
            return doc
        } catch {
            print("⚠️ Users 컬랙션에 문서 없음")
            return nil
        }
    }
}


extension JSWebViewModel {
    func handlePushNavigation(userInfo: [AnyHashable: Any], completion: @escaping (LHHouseModel?) -> Void) {
        guard let dtlUrl = userInfo["dtlUrl"] as? String,
              let panId = userInfo["panId"] as? String
        else {
            completion(nil)
            return
        }
        
        fetchLHHouseForPanId(userInfo: userInfo) { lhhoushModel in
            completion(lhhoushModel)
        }
    }
}
