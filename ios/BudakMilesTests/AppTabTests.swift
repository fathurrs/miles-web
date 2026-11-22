import XCTest
@testable import BudakMiles

final class AppTabTests: XCTestCase {
    func testRootURLs() {
        XCTAssertEqual(AppTab.kalkulator.rootURL.absoluteString, "https://budakmiles.id/")
        XCTAssertEqual(AppTab.rute.rootURL.absoluteString, "https://rute.budakmiles.id/")
        XCTAssertEqual(AppTab.tersimpan.rootURL.absoluteString, "https://rute.budakmiles.id/#tersimpan")
        XCTAssertEqual(AppTab.milesSaya.rootURL.absoluteString, "https://rute.budakmiles.id/tukar-miles")
    }

    func testEveryRootURLMapsBackToItsTab() {
        for tab in AppTab.allCases {
            XCTAssertEqual(AppTab.tab(for: tab.rootURL), tab)
        }
    }

    func testTitlesAreIndonesianAndUnique() {
        XCTAssertEqual(AppTab.allCases.map(\.title), ["Kalkulator", "Cari Rute", "Tersimpan", "Miles Saya"])
    }

    func testSites() {
        XCTAssertEqual(AppTab.kalkulator.site, .main)
        XCTAssertEqual(Set(AppTab.allCases.filter { $0.site == .rute }), [.rute, .tersimpan, .milesSaya])
        XCTAssertNil(Site(url: URL(string: "https://example.com")!))
    }
}
