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


var expandWebViewCloseHandler = PassthroughSubject<Bool, Never>()
var lhhouseAlarmYNHandler = PassthroughSubject<Bool, Never>()

class JSWebViewModel: ObservableObject {
    @Published var deviceUUID: String = ""
    @Published var pushToken: String = ""
    @Published var osType: String = "i"              // 0 : iOS, 1 : Android, 2 : 기타
    @Published var receivedMessage: String = ""
    
    @Published var presentedDetail: LHHouseFileDownModel? = nil
    @Published var pushedViewDetail: LHHouseModel? = nil
    
    @Published var lhhouseFavorites: [LHHouseInfo] = []
    
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
        
        setLHHouseNotiSettingRequest(isRegister, lhhouseInfo: lhHouseModel)
        
        completion(isRegister)
    }
    
    func fetchLHHouseItem(_ lhHouseModel: LHHouseModel, completion: @escaping(Bool) -> Void) {
        guard let realm = realm else { return }
        let results = realm.objects(LHHouseInfo.self)
        let lhhouseInfo = results.filter( { $0.PAN_ID == lhHouseModel.PAN_ID } )
        
        print("PAN_IO: \(lhHouseModel.PAN_ID), CNP_CD_NM: \(lhHouseModel.CNP_CD_NM), PAN_SS : \(lhHouseModel.PAN_SS), AIS_TP_CD_NM: \(lhHouseModel.AIS_TP_CD_NM), UPP_AIS_TP_CD: \(lhHouseModel.UPP_AIS_TP_CD), PAN_NT_ST_DT : \(lhHouseModel.PAN_NT_ST_DT), CLSG_DT: \(lhHouseModel.CLSG_DT)")
        
        
        completion(lhhouseInfo.isEmpty == false)
    }
    
    func setLHHouseNotiSettingRequest(_ isOn: Bool = true, lhhouseInfo: LHHouseModel) {
        let client = FirestoreRESTClient()
        
        if isOn {
            Task {
                try await client.setDocument(
                    collection: "users",
                    documentId: deviceUUID,
                    fields: [
                        "CNP_CD_NM" : lhhouseInfo.CNP_CD_NM,
                    ]
                    
                )
            }
        } else {
            Task {
                try await client.deleteDocument(
                    collection: "users",
                    documentId: deviceUUID
                )
            }
        }
    }
}
