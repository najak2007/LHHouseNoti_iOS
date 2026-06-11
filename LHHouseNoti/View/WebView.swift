//
//  WebView.swift
//  LHHouseNoti
//
//  Created by najak on 6/11/26.
//

import SwiftUI
import WebKit

struct JSWebView: UIViewRepresentable {
    let url: URL
    
    @Binding var messageFromWeb: String
    let deviceUUID = DeviceIdentifier.shared.getDeviceUUID()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        
        // 💡 1. JavaScript -> Native 메시지를 받기 위한 핸들러 등록
        // 웹쪽 코드에서 window.webkit.messageHandlers.bridge.postMessage(데이터) 로 호출하게 됩니다.
        contentController.add(context.coordinator, name: "pushTokenReq")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    // 💡 2. Native -> JavaScript 함수를 호출하는 메서드 (외부 제어용)
    // 뷰의 상태 변경 등으로 웹의 JS를 실행하고 싶을 때 사용합니다.
    static func runJavaScript(on webView: WKWebView, script: String) {
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ 자바스크립트 실행 실패: \(error.localizedDescription)")
            } else if let result = result {
                print("✅ 자바스크립트 실행 성공 결과: \(result)")
            }
        }
    }

    // MARK: - Coordinator (JavaScript 메시지 수신부)
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: JSWebView

        init(_ parent: JSWebView) {
            self.parent = parent
        }

        // 웹에서 postMessage를 보내면 이 메서드가 호출됩니다.
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // 등록한 이름("bridge")이 맞는지 확인
            if message.name == "pushTokenReq" {
                if let messageBody = message.body as? String {
                    print("📱 웹으로부터 받은 메시지: \(messageBody)")
                    // SwiftUI 뷰의 상태 업데이트
                    DispatchQueue.main.async {
                        self.parent.messageFromWeb = messageBody
                    }
                }
            }
        }
    }
    
    func sendDeviceInfoToWeb() {
        let token = "1234"
        

        
    }
}
