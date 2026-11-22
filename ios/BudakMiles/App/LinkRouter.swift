import Foundation

/// Decides where a navigation inside one of the app's web views should go.
enum LinkRouter {
    enum Decision: Equatable {
        case stayInWebView
        case switchTab(AppTab, URL)
        case openExternally(URL)
    }

    /// Hosts that must load inside the web view (OAuth login for rute.budakmiles.id).
    static let inAppHosts: Set<String> = ["seats.aero"]

    private static let webViewSchemes: Set<String> = ["http", "https", "about", "data", "blob", "javascript"]

    static func decide(url: URL, from tab: AppTab, isLinkActivation: Bool, isMainFrame: Bool) -> Decision {
        let scheme = url.scheme?.lowercased() ?? ""
        if !webViewSchemes.contains(scheme) {
            return .openExternally(url)
        }
        guard scheme == "http" || scheme == "https", isLinkActivation, isMainFrame else {
            return .stayInWebView
        }
        let host = normalizedHost(url)
        if inAppHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
            return .stayInWebView
        }
        guard let site = Site(url: url) else {
            return .openExternally(url)
        }
        if site == tab.site {
            return .stayInWebView
        }
        return .switchTab(AppTab.tab(for: url) ?? (site == .main ? .kalkulator : .rute), url)
    }

    static func normalizedHost(_ url: URL) -> String {
        let host = (url.host ?? "").lowercased()
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
