import Foundation

enum AppConfig {
    static let userAgentSuffix = "BudakMilesApp/1.0 (iOS)"

    /// The rute tabs are separate pages on one origin that each keep a copy of their `mr:` localStorage
    /// data (e.g. the miles wallet) in memory; a tab whose copy went stale is reloaded when shown again.
    static let sharedStorageMessage = "sharedStorageChanged"
    static let sharedStorageWatchScript = """
    window.addEventListener('storage', function (e) {
      if (e.key === null || e.key.indexOf('mr:') === 0) {
        window.webkit.messageHandlers.\(sharedStorageMessage).postMessage(e.key || '');
      }
    });
    """

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
