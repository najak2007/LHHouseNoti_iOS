//
//  LocationUtils.swift
//  LHHouseNoti
//
//  Created by najak on 6/25/26.
//

import Foundation

enum LocationName: CaseIterable {
    case 서울특별시
    case 부산광역시
    case 대구광역시
    case 인천광역시
    case 광주광역시
    case 대전광역시
    case 울산광역시
    case 세종특별자치시
    case 경기도
    case 강원도
    case 충청북도
    case 충청남도
    case 전라북도
    case 전라남도
    case 경상북도
    case 경상남도
    case 제주특별자치도
}


class LocationUtils {
   static let shared = LocationUtils()
    private init() {}
    
    
    func getLocationCode(cnpCdNM: String) -> String {
        switch cnpCdNM {
        case "서울특별시":
            return "11";
        case "부산광역시":
            return "26";
        case "대구광역시":
            return "27";
        case "인천광역시":
            return "28";
        case "광주광역시":
            return "29";
        case "대전광역시":
            return "30";
        case "울산광역시":
            return "31";
        case "세종특별자치시":
            return "36110";
        case "경기도":
            return "41";
        case "강원도":
            return "42";
        case "충청북도":
            return "43";
        case "충청남도":
            return "44";
        case "전라북도":
            return "52";
        case "전라남도":
            return "46";
        case "경상북도":
            return "47";
        case "경상남도":
            return "48";
        case "제주특별자치도":
            return "50";
        default:
            return ""; // 기본값은 서울로 설정
        }
    }
}
