//
//  WebView.swift
//  LHHouseNoti
//
//  Created by najak on 6/11/26.
//

import SwiftUI
import WebKit

struct JSWebView: UIViewRepresentable {
    @ObservedObject var viewModel: JSWebViewModel
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // React → Swift 메시지 핸들러 등록
        userContentController.add(context.coordinator, name: "nativeBridge")
        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        viewModel.webView = webView // ViewModel에서 참조 가능하도록 저장
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 필요 시 업데이트 로직
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator (델리게이트 처리)
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let viewModel: JSWebViewModel

        init(viewModel: JSWebViewModel) {
            self.viewModel = viewModel
        }

        // 페이지 로드 완료 시 데이터 전달
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.sendDeviceInfoToWeb()
        }

        // React → Swift 메시지 수신
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "nativeBridge" {
                if let body = message.body as? String {
                    DispatchQueue.main.async {
                        self.viewModel.receivedMessage = body
                    }

                    if body == "deviceInfoReq" {
                        viewModel.sendDeviceInfoToWeb()
                    }
                }
            }
        }
    }
}
