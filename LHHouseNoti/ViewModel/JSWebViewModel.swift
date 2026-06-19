//
//  JSWebViewModel.swift
//  LHHouseNoti
//
//  Created by najak on 6/12/26.
//

import SwiftUI
import WebKit
import Combine


var expandWebViewCloseHandler = PassthroughSubject<Bool, Never>()

class JSWebViewModel: ObservableObject {
    @Published var deviceUUID: String = ""
    @Published var pushToken: String = ""
    @Published var osType: String = "i"              // 0 : iOS, 1 : Android, 2 : 기타
    @Published var receivedMessage: String = ""
    
    @Published var presentedDetail: WebViewDetail? = nil
    @Published var pushViewDetail: WebViewDetail? = nil
    
    weak var webView: WKWebView?
    
    init() {
        deviceUUID = DeviceIdentifier.shared.getDeviceUUID()
    }
    
    // React로 UUID + Token + OSType
    func sendDeviceInfoToWeb() {
        let token = pushToken.isEmpty ? "" : pushToken
        
        guard let uuidData = try? JSONEncoder().encode(deviceUUID),
              let tokenData = try? JSONEncoder().encode(token),
              let osTypeData = try? JSONEncoder().encode(osType),
              let uuidJSON = String(data: uuidData, encoding: .utf8),
              let tokenJSON = String(data: tokenData, encoding: .utf8),
              let osTypeJSON = String(data: osTypeData, encoding: .utf8)
        else { return }
        
        let script = "if(window.receiveDeviceInfo) { window.receiveDeviceInfo(\(uuidJSON), \(tokenJSON), \(osTypeJSON)) }"

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
}


struct WebViewDetail: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let PAN_ID: String
    let CNP_CD_NM: String
    let DTL_URL: String
    let PAN_SS: String
    let PAN_NM: String
    let AIS_TP_CD_NM: String
    let UPP_AIS_TP_CD: String
    let PAN_NT_ST_DT: String
    let CLSG_DT: String
}
