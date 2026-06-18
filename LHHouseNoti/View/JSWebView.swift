//
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
        // [핵심 추가] 상단 화살표 및 목록 버튼 클릭 감지 스크립트 주입
        // ------------------------------------------------------------------
        let jsString = """
        document.addEventListener('click', function(event) {
            // 1. 클릭된 요소가 화살표 이미지이거나 back 클래스를 가졌는지 체크
            // (LH 페이지의 실제 태그 속성에 맞게 조건을 추가/수정할 수 있습니다)
            var target = event.target;
            
            // 이미지나 아이콘을 클릭했을 때를 대비해 상위 부모태그까지 확인
            while (target && target !== document) {
                if (target.classList.contains('btn_back') || 
                    target.classList.contains('ico_back') || 
                    target.id === 'btnBack' ||
                    target.getAttribute('aria-label') === '이전화면' ||
                    target.textContent.trim() === '목록') {
                    
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
                
                // [핵심 추가] 상단 화살표 클릭 이벤트 수신 성공 시
                if action == "clickHeaderBackButton" {
                    print("LH 웹뷰 상단 화살표(뒤로가기) 클릭됨!")
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
