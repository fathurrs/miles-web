import XCTest
@testable import BudakMiles

final class LinkRouterTests: XCTestCase {
    private func decide(_ string: String, from tab: AppTab, link: Bool = true, mainFrame: Bool = true) -> LinkRouter.Decision {
        LinkRouter.decide(url: URL(string: string)!, from: tab, isLinkActivation: link, isMainFrame: mainFrame)
    }

    func testSameSiteLinksStayInWebView() {
        XCTAssertEqual(decide("https://budakmiles.id/kalkulator/bca", from: .kalkulator), .stayInWebView)
        XCTAssertEqual(decide("https://rute.budakmiles.id/jmb", from: .rute), .stayInWebView)
        XCTAssertEqual(decide("https://rute.budakmiles.id/asia-miles", from: .milesSaya), .stayInWebView)
        XCTAssertEqual(decide("https://rute.budakmiles.id/#tersimpan", from: .tersimpan), .stayInWebView)
    }

    func testWwwIsTreatedAsSameHost() {
        XCTAssertEqual(decide("https://www.budakmiles.id/about", from: .kalkulator), .stayInWebView)
        XCTAssertEqual(decide("https://WWW.BudakMiles.ID/", from: .kalkulator), .stayInWebView)
    }

    func testRuteLinkFromKalkulatorSwitchesTab() {
        let url = URL(string: "https://rute.budakmiles.id/")!
        XCTAssertEqual(decide(url.absoluteString, from: .kalkulator), .switchTab(.rute, url))
    }

    func testRuteDeepLinksSwitchToMatchingTab() {
        let saved = URL(string: "https://rute.budakmiles.id/#tersimpan")!
        XCTAssertEqual(decide(saved.absoluteString, from: .kalkulator), .switchTab(.tersimpan, saved))
        let tukar = URL(string: "https://rute.budakmiles.id/tukar-miles")!
        XCTAssertEqual(decide(tukar.absoluteString, from: .kalkulator), .switchTab(.milesSaya, tukar))
    }

    func testMainSiteLinkFromRuteTabsSwitchesToKalkulator() {
        let url = URL(string: "https://budakmiles.id/kalkulator")!
        for tab in [AppTab.rute, .tersimpan, .milesSaya] {
            XCTAssertEqual(decide(url.absoluteString, from: tab), .switchTab(.kalkulator, url))
        }
    }

    func testOAuthProviderStaysInWebView() {
        XCTAssertEqual(decide("https://seats.aero/oauth2/consent?client_id=x", from: .rute), .stayInWebView)
        XCTAssertEqual(decide("https://auth.seats.aero/login", from: .rute), .stayInWebView)
        XCTAssertNotEqual(decide("https://notseats.aero/", from: .rute), .stayInWebView)
    }

    func testOtherWebsitesOpenExternally() {
        for string in ["https://t.me/budakmiles", "https://www.instagram.com/budakmiles",
                       "https://pinterpoin.com/valuasi-poin-miles-tahun-2026/", "https://sosial.budakmiles.id/"] {
            XCTAssertEqual(decide(string, from: .kalkulator), .openExternally(URL(string: string)!), string)
        }
    }

    func testNonWebSchemesOpenExternally() {
        for string in ["mailto:hi@budakmiles.id", "tel:+62123", "sms:+62123", "tg://resolve?domain=budakmiles"] {
            XCTAssertEqual(decide(string, from: .rute, link: false), .openExternally(URL(string: string)!), string)
        }
    }

    func testRedirectsAndScriptNavigationsStayInWebView() {
        XCTAssertEqual(decide("https://rute.budakmiles.id/oauth/callback?code=1", from: .rute, link: false), .stayInWebView)
        XCTAssertEqual(decide("https://seats.aero/oauth2/consent", from: .rute, link: false), .stayInWebView)
        XCTAssertEqual(decide("https://www.googletagmanager.com/gtm.js", from: .kalkulator, link: false), .stayInWebView)
    }

    func testSubframeLoadsStayInWebView() {
        XCTAssertEqual(decide("https://www.youtube.com/embed/x", from: .kalkulator, mainFrame: false), .stayInWebView)
    }

    func testInternalSchemesStayInWebView() {
        XCTAssertEqual(decide("about:blank", from: .kalkulator), .stayInWebView)
        XCTAssertEqual(decide("data:text/plain,hi", from: .kalkulator), .stayInWebView)
    }
}
