//
//  ContentView.swift
//  LHHouseNoti
//
//  Created by najak on 6/11/26.
//

import SwiftUI

struct ContentView: View {
    @State private var textFromWeb: String = "아직 받은 메시지가 없습니다."
    
    // 원래는 상용 웹페이지 내부에 아래 [웹 측 코드 예시]가 구현되어 있어야 합니다.
    let targetURL = URL(string: "https://your-web-site.com")!

    var body: some View {
        VStack(spacing: 20) {
            // 1. 웹에서 온 데이터를 보여주는 영역
            VStack {
                Text("웹에서 넘겨준 데이터:")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(textFromWeb)
                    .font(.headline)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.top)

            // 2. JSWebView 배치
            JSWebView(url: targetURL, messageFromWeb: $textFromWeb)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 0.5)

            // 3. 앱에서 웹의 JavaScript를 호출하는 버튼 (예시)
            Button(action: {
                // 웹페이지에 'showAlertFromServer("안녕하세요!")' 라는 JS 함수가 있다고 가정하고 호출
                let jsCode = "showAlertFromServer('SwiftUI에서 보낸 알림입니다!')"
                
                // 실제 상용 환경에서는 특정 WKWebView 인스턴스를 찾아 주입해야 합니다.
                // 이 예시는 연동 개념을 보여주기 위한 가이드라인입니다.
            }) {
                Text("웹의 JavaScript 함수 호출하기")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}
