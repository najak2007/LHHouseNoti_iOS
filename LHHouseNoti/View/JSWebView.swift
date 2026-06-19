//  WebView.swift
//  LHHouseNoti
//

import SwiftUI
import WebKit
import Combine

struct JSWebView: UIViewRepresentable {
    @ObservedObject var viewModel: JSWebViewModel
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // React → Swift 메시지 핸들러 등록
        userContentController.add(context.coordinator, name: "nativeBridge")
        
        // ------------------------------------------------------------------
        // [수정/확장] 하단 메뉴바 제거 및 기존 클릭 감지 스크립트
        // ------------------------------------------------------------------
        // makeUIView(context:) 내부의 jsString 정의 부분 수정
        let jsString = """
        (function() {
            // 1. 💡 전역 CSS 규칙 주입 (새로 요청하신 id와 class 추가)
            // #mNav, #header 요소를 아예 생성 단계부터 원천 차단합니다.
            var styleNode = document.createElement('style');
            styleNode.type = 'text/css';
            var cssRules = '#mNav, #header { display: none !important; visibility: hidden !important; opacity: 0 !important; pointer-events: none !important; height: 0 !important; width: 0 !important; }';
            styleNode.innerHTML = cssRules;
            document.documentElement.appendChild(styleNode);

            // 2. 💡 MutationObserver를 활용해 요소가 동적으로 다시 켜지거나 생성될 때 강제 제어 (2중 보안)
            var observer = new MutationObserver(function(mutations) {
                // ID 타겟팅 감지 및 제어
                var mNav = document.getElementById('mNav');
                if (mNav) {
                    mNav.style.setProperty('display', 'none', 'important');
                    mNav.style.setProperty('visibility', 'hidden', 'important');
                }
                
                var header = document.getElementById('header');
                if (header) {
                    header.style.setProperty('display', 'none', 'important');
                    header.style.setProperty('visibility', 'hidden', 'important');
                }

                // body가 생겼을 때만 패딩 제거 (에러 방지 안전장치)
                if (document.body) {
                    document.body.style.setProperty('padding-bottom', '0px', 'important');
                    document.body.style.setProperty('padding-top', '0px', 'important');
                }
            });
            
            observer.observe(document.documentElement, {
                childList: true,
                subtree: true
            });
        })();

        // 3. 💡 뒤로가기 이벤트 리스너 (기존 코드 유지)
        document.addEventListener('click', function(event) {
            var target = event.target;
            
            while (target && target !== document) {
                var isLHBack = target.classList.contains('btn_back') || 
                               target.classList.contains('ico_back') || 
                               target.id === 'btnBack' ||
                               target.getAttribute('aria-label') === '이전화면' ||
                               target.textContent.trim() === '목록';
                               
                var href = target.getAttribute('href') || '';
                var isJsHistoryBack = href.toLowerCase().includes('javascript:history.back');

                if (isLHBack || isJsHistoryBack) {
                    window.webkit.messageHandlers.nativeBridge.postMessage({
                        "action": "clickHeaderBackButton"
                    });
                    break;
                }
                target = target.parentNode;
            }
        }, true);
        
        // JSWebView의 jsString 내부에 추가할 로직
        document.addEventListener('click', function(event) {
            var target = event.target;
            while (target && target !== document) {
                var href = target.getAttribute('href') || '';
                
                // 💡 href에 javascript:saveItrPan이 포함되어 있는지 체크
                if (href.toLowerCase().includes('javascript:saveitrpan')) {
                    window.webkit.messageHandlers.nativeBridge.postMessage({
                        "action": "clickSaveItrPan"
                    });
                    break;
                }
                target = target.parentNode;
            }
        }, true);
        
        
        """

        // ⚠️ 중요: 주입 타이밍은 반드시 가장 빠른 .atDocumentStart여야 합니다.
        let userScript = WKUserScript(source: jsString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
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
            
            // ------------------------------------------------------------------
            // 💡 [추가] 웹뷰 로딩이 완전히 끝난 시점(Ajax dynamic load 대응)에 다시 한번 숨김 처리 실행
            // ------------------------------------------------------------------
            let hideScript = """
            var footerNav = document.getElementById('mNav');
            if (footerNav) {
                footerNav.style.setProperty('display', 'none', 'important');
            }
            
            var header = document.getElementById('header');
            if (header) {
                header.style.setProperty('display', 'none', 'important');
            }
            
            
            document.body.style.setProperty('padding-bottom', '0px', 'important');
            document.body.style.setProperty('padding-top', '0px', 'important');
            """
            webView.evaluateJavaScript(hideScript, completionHandler: nil)
            // ------------------------------------------------------------------
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if isInitialLoad {
                isInitialLoad = false
                decisionHandler(.allow)
                return
            }
            
            if let url = navigationAction.request.url, url.scheme == "javascript" {
                let absoluteString = url.absoluteString.lowercased()
                if absoluteString.contains("history.back") {
                    print("decidePolicyFor: javascript:history.back() 클릭 감지됨")
                    decisionHandler(.cancel)
                    return
                }
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
                if let body = message.body as? String {
                    DispatchQueue.main.async {
                        self.viewModel.receivedMessage = body
                    }
                    if body == "deviceInfoReq" {
                        viewModel.sendDeviceInfoToWeb()
                    }
                    return
                }

                guard let body = message.body as? [String: Any],
                      let action = body["action"] as? String else {
                    return
                }
                
                if action == "clickHeaderBackButton" {
                    print("LH 웹뷰 상단 화살표 또는 history.back() 클릭됨!")
                    expandWebViewCloseHandler.send(true)
                    return
                }
                
                if action == "clickSaveItrPan" {
                    print("관심공고 등록이 클릭됨!")
                    
                }
                
                if action == "openWebView", let urlString = body["url"] as? String, let bodyDic = message.body as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: bodyDic, options: .prettyPrinted)
                        let lhhoueseItemDic = try JSONDecoder().decode(LHHouseModel.self, from: jsonData)
                        expandWebView(houseNotiDict: lhhoueseItemDic)
                    } catch {
                        
                    }
                }
            }
        }
        
        private func expandWebView(houseNotiDict: LHHouseModel) {
            DispatchQueue.main.async {
                self.viewModel.presentedDetail = houseNotiDict
            }
        }
    }
}
