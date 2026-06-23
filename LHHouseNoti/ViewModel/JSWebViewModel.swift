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


var expandWebViewCloseHandler = PassthroughSubject<Bool, Never>()

class JSWebViewModel: ObservableObject {
    @Published var deviceUUID: String = ""
    @Published var pushToken: String = ""
    @Published var osType: String = "i"              // 0 : iOS, 1 : Android, 2 : 기타
    @Published var receivedMessage: String = ""
    
    @Published var presentedDetail: LHHouseFileDownModel? = nil
    @Published var pushedViewDetail: LHHouseModel? = nil
    
    @Published var lhhouseFavorites: [LHHouseInfo] = []
    
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
        let results = realm.objects(LHHouseInfo.self)
        lhhouseFavorites = Array(results).sorted(by: { $0.registerDate > $1.registerDate })
    }
    
    func saveLHHouseFavorite(_ lhHouseModel: LHHouseModel, completion: @escaping(Bool) -> Void) {
        guard let realm = realm
        else {
            completion(false)
            return
        }
        let results = realm.objects(LHHouseInfo.self)
        let lhhouseInfo = results.filter( { $0.PAN_ID == lhHouseModel.PAN_ID } )
        
        do {
            if lhhouseInfo.isEmpty == true {
                let lhHouseInfo = LHHouseInfo(lhHouseModel)
                try realm.write {
                    realm.add(lhHouseInfo)
                    completion(true)
                }
            } else {
                try realm.write {
                    realm.delete(lhhouseInfo)
                    completion(false)
                }
            }
        } catch {
            
        }
    }
    
    func fetchLHHouseItem(_ lhHouseModel: LHHouseModel, completion: @escaping(Bool) -> Void) {
        guard let realm = realm else { return }
        let results = realm.objects(LHHouseInfo.self)
        let lhhouseInfo = results.filter( { $0.PAN_ID == lhHouseModel.PAN_ID } )
        
        print("PAN_IO: \(lhHouseModel.PAN_ID), CNP_CD_NM: \(lhHouseModel.CNP_CD_NM), PAN_SS : \(lhHouseModel.PAN_SS), AIS_TP_CD_NM: \(lhHouseModel.AIS_TP_CD_NM), UPP_AIS_TP_CD: \(lhHouseModel.UPP_AIS_TP_CD), PAN_NT_ST_DT : \(lhHouseModel.PAN_NT_ST_DT), CLSG_DT: \(lhHouseModel.CLSG_DT)")
        
        
        completion(lhhouseInfo.isEmpty == false)
    }
}
