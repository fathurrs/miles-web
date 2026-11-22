import Foundation

enum AppConfig {
    static let userAgentSuffix = "BudakMilesApp/1.0 (iOS)"

    /// The sites draw their own bottom menu (`nav.tabbar`); the app's tab bar replaces it.
    static let hideWebTabBarScript = """
    (function () {
      if (!/(^|\\.)budakmiles\\.id$/.test(location.hostname)) return;
      var style = document.createElement('style');
      style.id = 'budakmiles-app';
      style.textContent = 'nav.tabbar, #tbSheet { display: none !important; }';
      (document.head || document.documentElement).appendChild(style);
    })();
    """

    /// UI tests pass `-UITestUnreachable` to point every tab at a host that never resolves.
    static var isUnreachableMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestUnreachable")
            || ProcessInfo.processInfo.environment["UITEST_UNREACHABLE"] == "1"
    }

    static func rootURL(for tab: AppTab) -> URL {
        isUnreachableMode ? URL(string: "https://\(tab.rawValue).unreachable.invalid/")! : tab.rootURL
    }
}
