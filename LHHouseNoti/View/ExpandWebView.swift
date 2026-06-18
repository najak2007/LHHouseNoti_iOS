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
        NavigationView {
            JSWebView(viewModel: jsWebViewModel, url: url)
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
        }
    }
}
