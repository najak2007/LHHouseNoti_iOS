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
    @Published var usersInfo: [String: Any] = [:]
    
    private var notificationToken: NotificationToken?  // 추가
    
    weak var webView: WKWebView?
    
    private var realm: Realm?
    
    init() {
        deviceUUID = DeviceIdentifier.shared.getDeviceUUID()
        realm = RealmManager.shared.realm
        
        fetchLHHouseData()
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
                    self.lhhouseFavorites = Array(results)
                }
            case .error(let error):
                print("Realm observe 에러: \(error)")
            }
        }
    }

    deinit {
        notificationToken?.invalidate()  // 추가
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
                    let newHouseInfo = LHHouseInfo(lhHouseModel)
                    realm.add(newHouseInfo)
                    isRegister = true
                } else {
                    // Realm의 Results 타입을 그대로 delete에 전달하여 안전하게 삭제
                    realm.delete(targets)
                    isRegister = false
                }
            }
        } catch {
            print("Realm 에러: \(error)")
            completion(false)
            return
        }
        
        // 중요: 여기서 UI가 참조하는 배열이나 뷰모델의 데이터를 완전히 새로고침 해줘야 합니다.
        fetchLHHouseData()
        completion(isRegister)
    }
    
    func fetchLHHouseItem(_ lhHouseModel: LHHouseModel, completion: @escaping(Bool) -> Void) {
        guard let realm = realm else { return }
        let results = realm.objects(LHHouseInfo.self)
        let lhhouseInfo = results.filter( { $0.PAN_ID == lhHouseModel.PAN_ID } )
        
        print("PAN_IO: \(lhHouseModel.PAN_ID), CNP_CD_NM: \(lhHouseModel.CNP_CD_NM), PAN_SS : \(lhHouseModel.PAN_SS), AIS_TP_CD_NM: \(lhHouseModel.AIS_TP_CD_NM), UPP_AIS_TP_CD: \(lhHouseModel.UPP_AIS_TP_CD), PAN_NT_ST_DT : \(lhHouseModel.PAN_NT_ST_DT), CLSG_DT: \(lhHouseModel.CLSG_DT)")
        
        
        completion(lhhouseInfo.isEmpty == false)
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
        guard !editFielsList.contains(fieldItem)
        else {
            print("⚠️ 이미 등록된 \(fieldKey): \(fieldItem)")
            return
        }
        
        editFielsList.append(fieldItem)
        usersNotiDic.updateValue(editFielsList, forKey: fieldKey)
        
        // 4. 저장
        try await FirestoreRESTClient.shared.setDocument(
            collection: "users",
            documentId: deviceUUID,
            fields: usersNotiDic)
        
        Analytics.setUserProperty(fieldItem, forName: fieldKey)
        
        usersInfo = usersNotiDic
        
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
        editFielsList.removeAll { $0 == fieldItem }

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
            Analytics.setUserProperty(nil, forName: "a")
        }
        
        usersInfo = usersNotiDic
    }
    
    private func fetchUserFields() async throws -> [String: Any]?  {
        do {
            let doc = try await FirestoreRESTClient.shared.getDocument(
                collection: "users",
                documentId: deviceUUID
            )
            return doc
        } catch {
            print("⚠️ Users 컬랙션에 문서 없음")
            return nil
        }
    }
}
