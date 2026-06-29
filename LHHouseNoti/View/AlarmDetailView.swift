//
//  AlarmDetailView.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/29/26.
//

import SwiftUI

struct AlarmDetailView: View {
    
    @ObservedObject var viewModel: JSWebViewModel
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Text("알림")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.leading, 20)
                    Spacer()
                }
                .frame(height: 45)
                
                Text("AlarmDetailView")
                
                Spacer()
            }
        }
    }
}
