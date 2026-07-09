//
//  AlarmReceiveView.swift
//  LHHouseNoti
//
//  Created by najak on 7/4/26.
//

import SwiftUI

struct AlarmReceiveView: View {
    @ObservedObject var viewModel: JSWebViewModel

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("받은 알림")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.leading, 20)
                    Spacer()
                }
                .frame(height: 45)
                
                if viewModel.lhhouseAlarms.count == 0 {
                    Spacer()
                    
                    Text("받은 알림이 없습니다.")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.gray)
                    
                    Spacer()
                    
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.lhhouseAlarms, id: \.PAN_ID) { item in
                                Button {
                                    viewModel.pushedViewDetail = item.lhhouseModel
                                } label: {
                                    NoticeCardView(viewModel: viewModel, item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 15)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 76)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.97, green: 0.98, blue: 0.98))
                }
            }
        }
    }
}
