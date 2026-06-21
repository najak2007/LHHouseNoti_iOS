//
//  RealmManager.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/19/26.
//

import RealmSwift
import Foundation

class RealmManager {
    static let shared = RealmManager()
    
    private init() {}
    
    var realm: Realm {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.sooyean")
        let realmURL = container?.appendingPathComponent("lhhouseAlarmi.realm")

#if DELETE_USE
        try! FileManager.default.removeItem(at: realmURL!)
#endif

        let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 1)
        return try! Realm(configuration: config)
    }
}
