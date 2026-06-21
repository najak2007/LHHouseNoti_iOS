//
//  LHHouseModel.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/19/26.
//

import Foundation

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
