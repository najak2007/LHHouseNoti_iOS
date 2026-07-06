//
//  ExpandWebView.swift
//  LHHouseNoti
//
//  Created by najak on 6/18/26.
//

import SwiftUI
import Foundation

struct ExpandWebView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var jsWebViewModel = JSWebViewModel()
    @State private var isFavorite: Bool = false
    
    let lhhouseModel: LHHouseModel
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea() // 노치/홈 인디케이터 영역까지 흰색으로 채움
            VStack {
                HStack {
                    HStack(spacing: 8) {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "arrow.backward")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.black)
                                .frame(width: 20, height: 20)
                        })
                        
                        Text(lhhouseModel.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        self.jsWebViewModel.saveLHHouseFavorite(lhhouseModel) { isFavorite in
                            self.isFavorite = isFavorite
                        }
                    }, label: {
                        Image(systemName: self.isFavorite == false ? "star" : "star.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                    })
                    .padding(.trailing, 20)
                    .onAppear {
                        self.jsWebViewModel.fetchLHHouseItem(lhhouseModel) { isFavorite in
                            self.isFavorite = isFavorite
                        }
                    }
                }
                
                
                JSWebView(viewModel: jsWebViewModel, url: URL(string: lhhouseModel.DTL_URL)!)
#if false
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                            }
                        }
                    }
#endif
                    .onReceive(expandWebViewCloseHandler) { _ in
                        dismiss()
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
