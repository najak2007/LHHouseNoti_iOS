//
//  UIDevice.swift
//  LHHouseNoti
//
//  Created by najak on 6/23/26.
//

import UIKit

public extension UIDevice {
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    var detailedModelName: String {
        let identifier = modelIdentifier
        switch identifier {
        case "iPod9,1":                                 return "iPod touch (7th generation)"
        case "iPhone14,7":                              return "iPhone 14"
        case "iPhone14,8":                              return "iPhone 14 Plus"
        case "iPhone15,2":                              return "iPhone 14 Pro"
        case "iPhone15,3":                              return "iPhone 14 Pro Max"
        case "iPhone15,4":                              return "iPhone 15"
        case "iPhone15,5":                              return "iPhone 15 Plus"
        case "iPhone16,1":                              return "iPhone 15 Pro"
        case "iPhone16,2":                              return "iPhone 15 Pro Max"
        case "i386", "x86_64", "arm64":                 return "Simulator (\(identifier))" // 시뮬레이터
        default:                                        return identifier // 리스트에 없는 신기종은 식별 코드 그대로 반환
        }
    }
}

