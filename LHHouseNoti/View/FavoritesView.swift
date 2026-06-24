//
//  FavoritesView.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/23/26.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: JSWebViewModel
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("즐겨찾기")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.leading, 20)
                    Spacer()
                }
                .frame(height: 45)
                
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.lhhouseFavorites, id: \.PAN_ID) { item in
                            Button {
                                viewModel.pushedViewDetail = item.lhhouseModel
                            } label: {
                                NoticeCardView(item: item)
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
