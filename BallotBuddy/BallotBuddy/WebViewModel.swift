import Foundation
import WebKit
import UIKit

// MARK: - WebViewModel
// ObservableObject that owns the WKWebView instance and exposes reactive state.
// All existing WKNavigationDelegate, WKUIDelegate, and NativeFeaturesBridge
// logic is preserved exactly in WebViewNavigationCoordinator below.

class WebViewModel: NSObject, ObservableObject {
    let webView: WKWebView

    @Published var currentTitle: String = "Ballot Buddy"
    @Published var currentURL: URL? = nil

    private let coordinator: WebViewNavigationCoordinator

    override init() {
        // --- Build WKWebView configuration ---
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let contentController = WKUserContentController()
        let bridge = NativeFeaturesBridge()
        contentController.add(bridge, name: "nativeApp")
        configuration.userContentController = contentController

        // --- Create the shared WKWebView ---
        let wkWebView = WKWebView(frame: .zero, configuration: configuration)
        self.webView = wkWebView
        self.coordinator = WebViewNavigationCoordinator()

        super.init()

        // Wire up the bridge and delegates (requires self to be fully init'd)
        bridge.webView = wkWebView
        wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = .clear
        wkWebView.navigationDelegate = coordinator
        wkWebView.uiDelegate = coordinator

        // Load the bundled index.html
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            wkWebView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        // KVO to track page title and URL changes
        wkWebView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        wkWebView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "title")
        webView.removeObserver(self, forKeyPath: "URL")
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch keyPath {
            case "title":
                let raw = self.webView.title ?? ""
                self.currentTitle = raw.isEmpty ? "Ballot Buddy" : raw
            case "URL":
                self.currentURL = self.webView.url
            default:
                break
            }
        }
    }

    // MARK: - Public API

    /// Passes a search query into the web layer via JavaScript.
    func evaluateSearch(_ query: String) {
        let escaped = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("window.nativeSearch('\(escaped)')", completionHandler: nil)
    }

    /// Loads an arbitrary URL in the WebView (used by BookmarksView tap action).
    func load(url: URL) {
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }
}

// MARK: - WebViewNavigationCoordinator
// Preserves all existing WKNavigationDelegate and WKUIDelegate logic exactly.

class WebViewNavigationCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

    // Intercept navigation — open external URLs in Safari
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if url.isFileURL {
            decisionHandler(.allow)
            return
        }

        if let scheme = url.scheme, scheme == "http" || scheme == "https" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    // Handle window.open(_blank) — open in Safari, return nil to prevent in-app WKWebView
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        if let scheme = url.scheme, scheme == "http" || scheme == "https" {
            UIApplication.shared.open(url)
        }
        return nil
    }

    // MARK: - JavaScript dialog support

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        rootViewController?.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        rootViewController?.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        rootViewController?.present(alert, animated: true)
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
