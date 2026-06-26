//
//  SectionHeaderView.swift
//  LHHouseNoti
//
//  Created by najak on 6/26/26.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var showAlignment: HeaderTextAlignment = .좌측정렬
    
    var body: some View {
        HStack {
            if showAlignment == .가운데정렬 || showAlignment == .우측정렬 {
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
            
            if showAlignment == .좌측정렬 || showAlignment == .가운데정렬 {
                Spacer()
            }
        }
    }
}
