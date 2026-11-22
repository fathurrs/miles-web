import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedTab: AppTab = .kalkulator
    let stores: [AppTab: WebViewStore]

    init() {
        var stores: [AppTab: WebViewStore] = [:]
        for tab in AppTab.allCases {
            stores[tab] = WebViewStore(tab: tab, rootURL: AppConfig.rootURL(for: tab))
        }
        self.stores = stores
        for store in stores.values {
            store.onRoute = { [weak self] decision in self?.handle(decision) }
        }
    }

    func store(for tab: AppTab) -> WebViewStore { stores[tab]! }

    var tabSelection: Binding<AppTab> {
        Binding(
            get: { self.selectedTab },
            set: { newTab in
                if newTab == self.selectedTab {
                    self.store(for: newTab).goHome()
                }
                self.selectedTab = newTab
            }
        )
    }

    func handle(_ decision: LinkRouter.Decision) {
        switch decision {
        case .stayInWebView:
            break
        case let .switchTab(tab, url):
            selectedTab = tab
            store(for: tab).load(url)
        case let .openExternally(url):
            UIApplication.shared.open(url)
        }
    }
}
