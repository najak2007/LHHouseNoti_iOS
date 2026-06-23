//
//  FavoritesView.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/23/26.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: JSWebViewModel
    // 예시 데이터 리스트 (실제 구현 시 viewModel 등에서 가져온 notices 배열을 바인딩하거나 사용하세요)
    @State private var notices: [LHHouseModel] = []

    var body: some View {
        ScrollView {
            // CSS: .card-list { display: grid; gap: 10px; width: 100%; }
            VStack(spacing: 10) {
                ForEach(notices, id: \.PAN_ID) { item in
                    Button {
                        var detailUrl = item.DTL_URL
                        
                        // 💡 LH 웹페이지 특성 처리 (&mi=1027 추가 로직)
                        if !detailUrl.isEmpty && !detailUrl.contains("mi=") {
                            let separator = detailUrl.contains("?") ? "&" : "?"
                            detailUrl = "\(detailUrl)\(separator)mi=1027"
                        }
                        
                        // 기존 모델을 복사하거나 업데이트하여 네비게이션 트리거
                        var updatedItem = item
                        updatedItem.DTL_URL = detailUrl
                        
                        // 💡 viewModel의 pushedViewDetail을 설정하여 화면을 이동시킵니다.
                        viewModel.pushedViewDetail = updatedItem
                    } label: {
                        NoticeCardView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle()) // 버튼 고유의 파란색 하이라이트 제거
                }
            }
            // CSS: .main-content-area { padding: 15px 12px 76px 12px; }
            .padding(.top, 15)
            .padding(.horizontal, 12)
            .padding(.bottom, 76)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // CSS: background-color: #f8f9fa;
        .background(Color(red: 0.97, green: 0.98, blue: 0.98))
    }
}
