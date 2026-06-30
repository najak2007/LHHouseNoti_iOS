//
//  String+Extension.swift
//  LHHouseNoti
//
//  Created by najak on 6/26/26.
//

import Foundation
import UIKit

extension String {
    var isNumber: Bool {
        if Int(self) != nil || Double(self) != nil {
            return true
        }
        return false
    }
    
    var htmlStringRemove: String {
        var plainString = self
        if let data = self.data(using: .utf8) {
            let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
                )
            plainString = attributedString?.string ?? self
        }
        return plainString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var getKey: String {
        guard let range = self.range(of: ":")
        else {
            return self
        }
        return String(self[..<range.lowerBound])
    }
    
    var getValue: String {
        guard let range = self.range(of: ":")
        else {
            return self
        }
        return String(self[range.upperBound...])
    }
    
    var getFirstValue: String {
        let value = self.components(separatedBy: "_").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value ?? self
    }
}
