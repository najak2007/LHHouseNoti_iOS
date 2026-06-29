//
//  NoticeCardView.swift
//  LHHouseNoti
//
//  Created by 오션블루 on 6/23/26.
//
import SwiftUI


struct NoticeCardView: View {
    var viewModel: JSWebViewModel
    let item: LHHouseInfo
    @State private var isAlarmOn: Bool = false
    

    
    var body: some View {
        // CSS: .notice-card
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. 뱃지 영역 (.badge-container)
            HStack {
                HStack(spacing: 6) {
                    // 공고상태 뱃지 (.badge-status: background #e6f7ed, text #219653)
                    Text(item.PAN_SS)
                        .font(.system(size: 13, weight: .bold))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.90, green: 0.97, blue: 0.93))
                        .foregroundColor(Color(red: 0.13, green: 0.59, blue: 0.33))
                        .cornerRadius(12)
                    
                    // 지역 뱃지 (.badge-region: background #e8f2ff, text #2f80ed)
                    Text(item.CNP_CD_NM)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.91, green: 0.95, blue: 1.00))
                        .foregroundColor(Color(red: 0.18, green: 0.50, blue: 0.93))
                        .cornerRadius(12)
                }
                Spacer()
#if false
                Button(action: {
                    self.viewModel.setLHHouseNotiSettingRequest(!isAlarmOn, panId: item.PAN_ID, cnpCDNM: item.CNP_CD_NM) { isResult in
                        if isResult {
                            isAlarmOn.toggle()
                        }
                    }
                }, label: {
                    Image(systemName: isAlarmOn == true ? "bell" : "bell.slash")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.black)
                })
                .padding(.trailing, 8)
                .onAppear {
                    isAlarmOn = item.isAlarmFlag
                }
#endif
            }
            .padding(.bottom, 8)
            
            // 2. 공고 제목 (.notice-title: font 16px, line-clamp: 2)
            Text(item.PAN_NM)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.20, green: 0.20, blue: 0.20)) // #333333
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
            
            // 3. 점선 구분선 (.notice-dates의 border-top: 1px dashed #f2f2f2)
            Line()
                .stroke(style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4]))
                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95)) // #f2f2f2
                .frame(height: 1)
                .padding(.vertical, 8)
            
            // 4. 날짜 영역 (.notice-dates: font 13px, color #828282)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("공고일:")
                        .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51)) // #828282
                    Text(item.PAN_NT_ST_DT)
                        .foregroundColor(Color(red: 0.20, green: 0.20, blue: 0.20)) // #333333
                        .font(.system(size: 13, weight: .medium))
                }
                
                HStack(spacing: 4) {
                    Text("마감일:")
                        .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                    Text(item.CLSG_DT)
                        .foregroundColor(Color(red: 0.92, green: 0.34, blue: 0.34)) // .deadline #eb5757
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .font(.system(size: 13))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        // border: 1px solid #e2e8f0, box-shadow 무드 반영
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

// 💡 점선을 그리기 위한 하위 컴포넌트 유틸리티
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
