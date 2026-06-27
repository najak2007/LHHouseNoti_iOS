//
//  Date+Extension.swift
//  LHHouseNoti
//
//  Created by najak on 6/22/26.
//

import Foundation
import SwiftUI

enum DateFormat: String {
    case HHmm = "HH:mm"
    case HHmmss = "HH:mm:ss"
    case Mde = "M/d(E)"
    case yyMMdd = "yy:MM:dd"
    case yyMMddDot = "yy.MM.dd"
    case yyMMddDotHHmm = "yy.MM.dd' 'HH:mm"
    case EEEEMMMMddyyyy = "EEEE MMMM dd,yyyy"
    case yyyyMMdd = "yyyyMMdd"
    case yyyyMMddHyphen = "yyyy-MM-dd"
    case yyyyMMddDot = "yyyy.MM.dd"
    case yyMMddDotE = "yy.MM.dd'('E')'"
    case MMdd = "MM/dd"
    case iso8601 = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    case iso86012 = "yyyy-MM-dd'T'HH:mm:ss.SS'Z'"
    case yyyyMMddHHmmss = "yyyy.MM.dd' 'HH:mm:ss"
    case yyyyMMddHyphenHHmmssColon = "yyyy-MM-dd' 'HH:mm:ss"
    case yyyyMMddHHmm = "yyyy/MM/dd' 'HH:mm"
    case yyyyMMddKR = "yyyy'년 'M'월 'd'일"
    case yyyyMMKR = "yyyy'년 'M'월"
    case MMddE = "MM/dd'('E')'"
    case HHmmForWeather = "HHmm"
    case yearWeek = "yyyyw"
    case ahmm = "a' 'h':'mm"
    case yearKR = "yyyy'년"
    case MMddDot = "MM.dd"
    case dd = "dd"
    case yyyy = "yyyy"
}

enum TimeZoneFormat: String {
    case Locale
    case UTC = "UTC"
    case KST = "Asia/Seoul"
    
    func getTimeZone() -> TimeZone {
        return (self == .Locale) ? .autoupdatingCurrent : TimeZone(identifier: self.rawValue)!
    }
}

extension Date {
    public func dateCompare(fromDate: Date) -> String {
        let dateFormatter: DateFormatter = .init()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let fromDateString: String = dateFormatter.string(from: fromDate)
        let selfDateString: String = dateFormatter.string(from: self)
        
        if fromDateString == selfDateString {
            return "S"      // 동일
        } else if fromDateString > selfDateString {
            return "F"      // 미래
        } else if fromDateString < selfDateString {
            return "P"      // 과거
        }

        return ""
    }
    
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        
        return range.compactMap { day -> Date in
            calendar.date(byAdding: .day, value: day - 1, to: startDate) ?? Date()
        }
    }
    
    func asString(format: DateFormat, timeZone: TimeZone? = TimeZone(abbreviation: "KST")) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = format.rawValue
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: self)
    }
    
    func now() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: now)
    }
    
    func getDateID() -> String {
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let newID: String = dateFormatter.string(from: date)
        return newID
    }
        
    var weekDay: String {
        let weekDay = Calendar.current.component(.weekday, from: self)
        if weekDay > 0 && weekDay < 8 {
            return Config.WEEKDAY_TITLE[weekDay - 1]
        }
        return ""
    }
    
    var isSunDay: Bool {
        let weekDay = Calendar.current.component(.weekday, from: self)
        if weekDay > 0 && weekDay < 8 {
            if Config.WEEKDAY_TITLE[weekDay - 1] == "일" {
                return true
            }
        }
        return false
    }
    
    var isToDay: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var startOfToday: Date {
        let now = self
        let calendar = Calendar.current
        return calendar.startOfDay(for: now)
    }
    
    var toDoListID: String {
        return "TODO\(getDateID())"
    }
    
    var HHmm: String{
        return asString(format: .HHmm)
    }
    
    var HHmmss: String{
        return asString(format: .HHmmss)
    }
    
    var Mde: String {
        return asString(format: .Mde)
    }
    
    var MMddDot: String {
        return asString(format: .MMddDot)
    }
    
    var yyMMdd: String{
        return asString(format: .yyMMdd)
    }
    
    var yyMMddDot: String {
        return asString(format: .yyMMddDot)
    }
    
    var yyMMddDotHHmm: String {
        return asString(format: .yyMMddDotHHmm)
    }
    
    var yyMMddDotE: String {
        return asString(format: .yyMMddDotE)
    }
    
    var EEEEMMMMddyyyy: String{
        return asString(format: .EEEEMMMMddyyyy)
    }
    
    var yyyyMMdd: String{
        return asString(format: .yyyyMMdd)
    }
    
    var yyyyMMddHyphen: String{
        return asString(format: .yyyyMMddHyphen)
    }
    
    var yyyyMMddDot: String {
        return asString(format: .yyyyMMddDot)
    }
    
    var MMddHHmm: String{
        return asString(format: .MMdd)
    }
    
    var yyyyMMddHHmmss: String {
        return asString(format: .yyyyMMddHHmmss)
    }
    
    var yyyyMMddHHmm: String {
        return asString(format: .yyyyMMddHHmm)
    }
    
    var yyyyMMddKR: String {
        return asString(format: .yyyyMMddKR)
    }
    
    var yyyyMMKR: String {
        return asString(format: .yyyyMMKR)
    }
    
    var yyyyKR: String {
        return asString(format: .yearKR)
    }
    
    var MMddE: String {
        return asString(format: .MMddE)
    }
    
    var HHmmForWeather: String {
        return asString(format: .HHmmForWeather)
    }
    
    var yearWeek: String {
        return asString(format: .yearWeek)
    }
    
    var ahmm: String {
        return asString(format: .ahmm)
    }
    
    var dd: String {
        return asString(format: .dd)
    }
    
    var yyyyy: String {
        return asString(format: .yyyy)
    }
    
    func subtractDayFromDate(_ date: Date, component: Calendar.Component, amount: Int) -> Date {               // 주어진 Date 에 amount 만큼 과거 날짜 반환
        return Calendar.current.date(byAdding: component, value: -amount, to: date) ?? date
    }
    
    func addDayFromDate(_ date: Date, component: Calendar.Component, amount: Int) -> Date {                    // 주어진 Date 에 amount 만큼 미래 날짜 반환
        return Calendar.current.date(byAdding: component, value: amount, to: date) ?? date
    }
    
    func findWeekRange(for date: Date) -> (start: Date, end: Date)? {
        var calendar = Calendar.current
        calendar.firstWeekday = 2       // 월요일 (일요일 = 1, 월요일 = 2, ... 토요일 = 7)
        
        var startOfWeek: Date = Date()
        var interval: TimeInterval = 0
        
        guard calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: date) else {
            return nil
        }
        
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return nil
        }
        
        return (start: startOfWeek, end: endOfWeek)
    }
    
    func findAllMondayOfMonth() -> [String] {         // 한달에 월요일만 찾아서 Date로 나오도록 개발
        var dates: [String] = []
        var calendar = Calendar.current
        let date: Date = self
        var nextDate: Date = Date()
        let startDate: Date = date.startOfToMonth
        var endIndex: Int = date.getAllDates().count - 1
        
        dates.append(startDate.dd)         // 월의 첫번째 날짜
        calendar.firstWeekday = 2       // 월요일
 
        let weekday = calendar.component(.weekday, from: startDate)
        
        if weekday == 1 {                   // 일요일
            guard let endOfWeek = calendar.date(byAdding: .day, value: 1, to: startDate) else {
                return dates
            }
            dates.append(endOfWeek.dd)
            nextDate = endOfWeek
            endIndex = endIndex - 2
        } else if weekday >= 2 && weekday <= 7 {            // 월요일
            guard let endOfWeek = calendar.date(byAdding: .day, value: 9 - weekday, to: startDate) else {
                return dates
            }
            dates.append(endOfWeek.dd)
            nextDate = endOfWeek
            endIndex = endIndex - (7 + weekday)
        }

        for _ in stride(from: 0, to: endIndex, by: 7) {
            guard let mondayDate = calendar.date(byAdding: .day, value: 7, to: nextDate) else {
                break
            }
            dates.append(mondayDate.dd)
            nextDate = mondayDate
        }

        return dates
    }
    
    func findCurrentYearInterval() -> Int {
        guard let startDate = Config.APP_START_DATE
        else {
            return 0
        }
        
        let components = Calendar.current.dateComponents([.year], from: startDate, to: self)
        
        guard let yearInt = components.year
        else {
            return 0
        }
        return yearInt == 0 ? 1 : yearInt
    }
    
    func findCurrentDayInterval() -> Int {
        let components = Calendar.current.dateComponents([.day], from: Date().startOfToday, to: self.startOfToday)
        guard let dayInt = components.day
        else {
            return 0
        }
        return dayInt
    }
    
    var startOfToMonth: Date {                  // 년/월에서 1일의 Date 찾기
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = Calendar.current.component(.month, from: self)
        components.day = 1
        return calendar.date(from: components)!
    }
    
    var endOfToMonth: Date {                    // 년/월에서 마지막 날짜의 Date 찾기
        let startDate = self.startOfToMonth
        let endDayInterval = startDate.getAllDates().count
        let endDate = Calendar.current.date(byAdding: .day, value: endDayInterval - 1, to: startDate)!
        return endDate
    }
    
    var startofToYear: Date {                   // 년도의 1월 1일 Date 찾기
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = 1
        components.day = 1
        return calendar.date(from: components)!
    }
    
    var endofToYear: Date {                     // 년도의 12월 31일의 Date 찾기
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = 12
        components.day = 31
        return calendar.date(from: components)!
    }
}
