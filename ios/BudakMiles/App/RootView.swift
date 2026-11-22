import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView(selection: model.tabSelection) {
            ForEach(AppTab.allCases) { tab in
                WebTabView(store: model.store(for: tab))
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
    }
}
