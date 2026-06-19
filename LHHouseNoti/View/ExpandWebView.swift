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

    let url: URL
    let title: String

    
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
                        
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "star")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                    })
                    .padding(.trailing, 20)
                }
                
                
                JSWebView(viewModel: jsWebViewModel, url: url)
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
