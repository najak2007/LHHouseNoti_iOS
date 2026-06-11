//
//  DeviceIdentifier.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/11/26.
//

import Foundation

class DeviceIdentifier {

    static let shared = DeviceIdentifier()
    private init() {}

    private let keychainAccount = "deviceUUID"

    /// 기기 고유 UUID 가져오기 (없으면 새로 생성 후 저장)
    func getDeviceUUID() -> String {
        // 1. Keychain에 기존 값이 있는지 확인
        if let existingUUID = KeychainHelper.shared.read(account: keychainAccount) {
            print("기존 UUID 사용: \(existingUUID)")
            return existingUUID
        }

        // 2. 없으면 새로 생성
        let newUUID = UUID().uuidString
        KeychainHelper.shared.save(newUUID, account: keychainAccount)
        print("새 UUID 생성 및 저장: \(newUUID)")
        return newUUID
    }
}
