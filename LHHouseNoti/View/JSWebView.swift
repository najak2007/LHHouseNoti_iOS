//  WebView.swift
//  LHHouseNoti
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
        
        // ------------------------------------------------------------------
        // [수정/확장] 기존 클릭 감지에 href="javascript:history.back();" 감지 스크립트 추가
        // ------------------------------------------------------------------
        let jsString = """
        document.addEventListener('click', function(event) {
            var target = event.target;
            
            while (target && target !== document) {
                // 기존 LH 조건 체크
                var isLHBack = target.classList.contains('btn_back') || 
                               target.classList.contains('ico_back') || 
                               target.id === 'btnBack' ||
                               target.getAttribute('aria-label') === '이전화면' ||
                               target.textContent.trim() === '목록';
                               
                // [추가] href 속성에 javascript:history.back이 포함되어 있는지 체크
                var href = target.getAttribute('href') || '';
                var isJsHistoryBack = href.toLowerCase().includes('javascript:history.back');

                if (isLHBack || isJsHistoryBack) {
                    // Swift의 nativeBridge로 이벤트 전송
                    window.webkit.messageHandlers.nativeBridge.postMessage({
                        "action": "clickHeaderBackButton"
                    });
                    break;
                }
                target = target.parentNode;
            }
        });
        """
        let userScript = WKUserScript(source: jsString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)
        // ------------------------------------------------------------------

        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        viewModel.webView = webView
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let viewModel: JSWebViewModel
        var isInitialLoad = true

        init(viewModel: JSWebViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.sendDeviceInfoToWeb()
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if isInitialLoad {
                isInitialLoad = false
                decisionHandler(.allow)
                return
            }
            
            // ------------------------------------------------------------------
            // [방법 1 추가] URL 스키마가 'javascript:history.back'인 경우 네이티브 액션 감지
            // ------------------------------------------------------------------
            if let url = navigationAction.request.url, url.scheme == "javascript" {
                let absoluteString = url.absoluteString.lowercased()
                if absoluteString.contains("history.back") {
                    print("decidePolicyFor: javascript:history.back() 클릭 감지됨")
                    
                    // 네이티브 뒤로가기/창닫기 등의 동작을 수행하도록 뷰모델에 전달합니다.
                    DispatchQueue.main.async {
                        // 예: self.viewModel.closeDetailView() 또는 관련 처리
                    }
                    
                    // 스크립트가 웹뷰 내에서 작동하길 원치 않으면 .cancel, 그대로 실행되길 원하면 .allow
                    decisionHandler(.cancel)
                    return
                }
            }
            // ------------------------------------------------------------------
            
            if navigationAction.navigationType != .linkActivated {
                print("차단된 리다이렉트 URL: \(navigationAction.request.url?.absoluteString ?? "")")
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        // 메시지 수신부
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "nativeBridge" {
                // 1. 문자열로 들어오는 경우 처리
                if let body = message.body as? String {
                    DispatchQueue.main.async {
                        self.viewModel.receivedMessage = body
                    }
                    if body == "deviceInfoReq" {
                        viewModel.sendDeviceInfoToWeb()
                    }
                    return
                }

                // 2. 딕셔너리([String: Any])로 들어오는 경우 처리
                guard let body = message.body as? [String: Any],
                      let action = body["action"] as? String else {
                    return
                }
                
                // [방법 2 작동] 상단 화살표 및 javascript:history.back() 이벤트 수신
                if action == "clickHeaderBackButton" {
                    print("LH 웹뷰 상단 화살표 또는 history.back() 클릭됨!")
                    // TODO: viewModel을 통해 현재 상세 웹뷰 창을 닫거나 목록으로 전송하는 로직 수행
                    // 예: DispatchQueue.main.async { self.viewModel.closeDetailView() }
                    return
                }
                
                if action == "openWebView", let urlString = body["url"] as? String {
                    expandWebView(urlString: urlString, title: body["title"] as? String ?? "")
                }
            }
        }
        
        private func expandWebView(urlString: String, title: String) {
            guard let url = URL(string: urlString) else { return }
            DispatchQueue.main.async {
                self.viewModel.presentedDetail = WebViewDetail(url: url, title: title)
            }
        }
    }
}
