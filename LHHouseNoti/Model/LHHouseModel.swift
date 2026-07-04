//
//  LHHouseModel.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/19/26.
//

import Foundation
import RealmSwift
internal import Realm

final class LHHouseInfo: Object, Comparable, Identifiable {
    @Persisted dynamic var  id: String = Date().getDateID()
    @Persisted dynamic var  isFavorite: Bool = false
    @Persisted dynamic var  DTL_URL: String = ""
    @Persisted dynamic var  title: String = ""
    @Persisted dynamic var  PAN_ID: String = ""
    @Persisted dynamic var  CNP_CD_NM: String = ""
    @Persisted dynamic var  PAN_SS: String = ""
    @Persisted dynamic var  PAN_NM: String = ""
    @Persisted dynamic var  AIS_TP_CD_NM: String = ""
    @Persisted dynamic var  UPP_AIS_TP_CD: String = ""
    @Persisted dynamic var  PAN_NT_ST_DT: String = ""
    @Persisted dynamic var  CLSG_DT: String = ""
    @Persisted dynamic var  registerDate: Date = Date()
    @Persisted dynamic var  isAlarmFlag: Bool = false
    
    override init() {
        super.init()
    }
    
    nonisolated override static func primaryKey() -> String? {
        return "PAN_ID"
    }
    
    init(DTL_URL: String = "", isFavorite: Bool = false, title: String = "", PAN_ID: String = "", CNP_CD_NM: String = "", PAN_SS: String = "", PAN_NM: String = "", AIS_TP_CD_NM: String = "", PAN_NT_ST_DT: String = "", CLSG_DT: String = "", isAlarmFlag: Bool = false) {
        self.DTL_URL = DTL_URL
        self.isFavorite = isFavorite
        self.title = title
        self.PAN_ID = PAN_ID
        self.CNP_CD_NM = CNP_CD_NM
        self.PAN_SS = PAN_SS
        self.PAN_NM = PAN_NM
        self.AIS_TP_CD_NM = AIS_TP_CD_NM
        self.PAN_NT_ST_DT = PAN_NT_ST_DT
        self.CLSG_DT = CLSG_DT
        self.isAlarmFlag = isAlarmFlag
    }
    
    init(_ lhHouseModel: LHHouseModel, isFavorite: Bool = false, isAlarmFlag: Bool = false) {
        self.DTL_URL = lhHouseModel.DTL_URL
        self.title = lhHouseModel.title
        self.PAN_ID = lhHouseModel.PAN_ID
        self.CNP_CD_NM = lhHouseModel.CNP_CD_NM
        self.PAN_SS = lhHouseModel.PAN_SS
        self.PAN_NM = lhHouseModel.PAN_NM
        self.AIS_TP_CD_NM = lhHouseModel.AIS_TP_CD_NM
        self.PAN_NT_ST_DT = lhHouseModel.PAN_NT_ST_DT
        self.CLSG_DT = lhHouseModel.CLSG_DT
        self.isFavorite = isFavorite
        self.isAlarmFlag = isAlarmFlag
    }
    
    static func < (lhs: LHHouseInfo, rhs: LHHouseInfo) -> Bool {
        return lhs.registerDate < rhs.registerDate
    }
    
    var lhhouseModel: LHHouseModel {
        return LHHouseModel(DTL_URL: self.DTL_URL, title: self.title, PAN_ID: self.PAN_ID, CNP_CD_NM: self.CNP_CD_NM, PAN_SS: self.PAN_SS, PAN_NM: self.PAN_NM, AIS_TP_CD_NM: self.AIS_TP_CD_NM, UPP_AIS_TP_CD: self.UPP_AIS_TP_CD, PAN_NT_ST_DT: self.PAN_NT_ST_DT, CLSG_DT: self.CLSG_DT)
    }
}

struct LHHouseModel: Codable, Hashable {
    let DTL_URL: String
    let title: String
    let PAN_ID: String
    let CNP_CD_NM: String
    let PAN_SS: String
    let PAN_NM: String
    let AIS_TP_CD_NM: String
    let UPP_AIS_TP_CD: String
    let PAN_NT_ST_DT: String
    let CLSG_DT: String
}

struct LHHouseFileDownModel: Codable, Identifiable {
    var id = UUID()
    
    let filepath: String
    let filename: String
    let fileext: String
    
    // 💡 CodingKeys에서 id를 제외하여, JSON에는 없다는 것을 명시합니다.
    enum CodingKeys: String, CodingKey {
        case filepath
        case filename
        case fileext
    }
}
