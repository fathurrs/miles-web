import Foundation
import UIKit
import WebKit

@MainActor
final class WebViewStore: NSObject, ObservableObject {
    let tab: AppTab
    let rootURL: URL
    let webView: WKWebView

    @Published private(set) var progress: Double = 0
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: Error?

    var onRoute: ((LinkRouter.Decision) -> Void)?

    private var lastRequestedURL: URL?
    private var observations: [NSKeyValueObservation] = []
    private var hasLoaded = false
    private var isStale = false

    init(tab: AppTab, rootURL: URL) {
        self.tab = tab
        self.rootURL = rootURL
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.applicationNameForUserAgent = AppConfig.userAgentSuffix
        config.allowsInlineMediaPlayback = true
        config.userContentController.addUserScript(WKUserScript(
            source: AppConfig.hideWebTabBarScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController.addUserScript(WKUserScript(
            source: AppConfig.sharedStorageWatchScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let messageProxy = WeakScriptMessageHandler()
        config.userContentController.add(messageProxy, name: AppConfig.sharedStorageMessage)
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        messageProxy.onMessage = { [weak self] in self?.isStale = true }

        webView.accessibilityIdentifier = "webView.\(tab.rawValue)"
        // WebKit's own swipe gesture never fires inside the SwiftUI TabView, so edge swipes are handled here.
        for edge in [UIRectEdge.left, .right] {
            let swipe = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(edgeSwipe(_:)))
            swipe.edges = edge
            swipe.delegate = self
            webView.addGestureRecognizer(swipe)
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refresh

        observations = [
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in self?.progress = webView.estimatedProgress }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in self?.isLoading = webView.isLoading }
            },
        ]
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        load(rootURL)
    }

    func load(_ url: URL) {
        hasLoaded = true
        isStale = false
        loadError = nil
        lastRequestedURL = url
        webView.load(URLRequest(url: url))
    }

    func reloadIfStale() {
        guard isStale, webView.url != nil else { return }
        isStale = false
        webView.reload()
    }

    func goHome() {
        load(rootURL)
    }

    func retry() {
        load(lastRequestedURL ?? rootURL)
    }

    @objc private func edgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let distance = gesture.translation(in: webView).x
        if gesture.edges == .left, distance > 60, webView.canGoBack {
            webView.goBack()
        } else if gesture.edges == .right, distance < -60, webView.canGoForward {
            webView.goForward()
        }
    }

    @objc private func pullToRefresh() {
        if webView.url == nil || loadError != nil {
            retry()
        } else {
            loadError = nil
            webView.reload()
        }
    }

    private func endRefreshing() {
        webView.scrollView.refreshControl?.endRefreshing()
    }

    private func handleFailure(_ error: Error) {
        endRefreshing()
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
        // WebKitErrorFrameLoadInterruptedByPolicyChange: the router took over the navigation.
        if nsError.domain == "WebKitErrorDomain" && nsError.code == 102 { return }
        loadError = error
    }
}

extension WebViewStore: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let decision = LinkRouter.decide(
            url: url,
            from: tab,
            isLinkActivation: navigationAction.navigationType == .linkActivated,
            isMainFrame: navigationAction.targetFrame?.isMainFrame ?? true
        )
        if decision == .stayInWebView {
            if navigationAction.targetFrame?.isMainFrame ?? false {
                lastRequestedURL = url
            }
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            onRoute?(decision)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadError = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        endRefreshing()
        loadError = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

extension WebViewStore: WKUIDelegate {
    /// Links with target="_blank" and window.open().
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        let decision = LinkRouter.decide(url: url, from: tab, isLinkActivation: true, isMainFrame: true)
        if decision == .stayInWebView {
            load(url)
        } else {
            onRoute?(decision)
        }
        return nil
    }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    var onMessage: (@MainActor () -> Void)?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated { onMessage?() }
    }
}

extension WebViewStore: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
