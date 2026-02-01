import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct WebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        // Configure WKWebView
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Set up message handlers for JavaScript bridge
        let contentController = WKUserContentController()
        let bridge = NativeFeaturesBridge()

        contentController.add(bridge, name: "nativeApp")

        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        bridge.webView = webView

        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear

        // Set delegates to handle external link navigation
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Load the local HTML file
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }

    // MARK: - Coordinator for WKNavigationDelegate & WKUIDelegate

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

        // Intercept navigation actions — open external URLs in Safari
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Allow local file loads (our bundled index.html)
            if url.isFileURL {
                decisionHandler(.allow)
                return
            }

            // External URL — open in Safari so user can return to the app
            if let scheme = url.scheme, (scheme == "http" || scheme == "https") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        // Handle window.open(_blank) calls — open in Safari
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }

            if let scheme = url.scheme, (scheme == "http" || scheme == "https") {
                UIApplication.shared.open(url)
            }

            // Return nil so no new WKWebView is created in-app
            return nil
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
