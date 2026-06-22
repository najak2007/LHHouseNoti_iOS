//
//  Config.swift
//  LHHouseNoti
//
//  Created by najak on 6/22/26.
//

import Foundation

class Config {
    static let WEEKDAY_TITLE: [String] = ["일", "월", "화", "수", "목", "금", "토"]
    static let APP_START_DATE: Date? = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 1))
}
