import SwiftUI
import WebKit

struct WebTabView: View {
    @ObservedObject var store: WebViewStore

    var body: some View {
        WebViewContainer(webView: store.webView)
            .overlay(alignment: .top) {
                if store.isLoading {
                    ProgressView(value: store.progress)
                        .progressViewStyle(.linear)
                        .accessibilityIdentifier("progressBar")
                }
            }
            .overlay {
                if store.loadError != nil {
                    ErrorView(retry: store.retry)
                }
            }
            .onAppear(perform: store.loadIfNeeded)
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ErrorView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Tidak dapat terhubung")
                .font(.title3.bold())
            Text("Periksa koneksi internetmu, lalu coba lagi.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Coba lagi", action: retry)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("retryButton")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("errorView")
    }
}
