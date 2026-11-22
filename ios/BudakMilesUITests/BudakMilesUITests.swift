import XCTest

final class BudakMilesUITests: XCTestCase {
    private let tabTitles = ["Kalkulator", "Cari Rute", "Tersimpan", "Miles Saya"]

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += arguments
        app.launch()
        return app
    }

    private func tabButton(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        app.tabBars.buttons[title]
    }

    private func webText(in webView: XCUIElement, containing text: String) -> XCUIElement {
        webView.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func testLaunchShowsAllTabs() {
        let app = launch()
        for title in tabTitles {
            XCTAssertTrue(tabButton(app, title).waitForExistence(timeout: 10), "Missing tab \(title)")
        }
        XCTAssertTrue(tabButton(app, "Kalkulator").isSelected)
    }

    func testKalkulatorTabLoadsBudakmiles() {
        let app = launch()
        let webView = app.webViews["webView.kalkulator"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15))
        XCTAssertTrue(webText(in: webView, containing: "miles kartu kredit").waitForExistence(timeout: 45))
        XCTAssertFalse(webView.otherElements["Menu cepat"].exists, "The site's own bottom menu should be hidden in the app")
    }

    func testRuteTabLoadsRouteFinder() {
        let app = launch()
        tabButton(app, "Cari Rute").tap()
        let webView = app.webViews["webView.rute"]
        XCTAssertTrue(webView.waitForExistence(timeout: 15))
        XCTAssertTrue(webText(in: webView, containing: "Rute Award").waitForExistence(timeout: 45))
        XCTAssertFalse(webView.otherElements["Menu cepat"].exists, "The site's own bottom menu should be hidden in the app")
    }

    func testTabSwitchingKeepsSelection() {
        let app = launch()
        for title in tabTitles.reversed() {
            let button = tabButton(app, title)
            button.tap()
            XCTAssertTrue(button.isSelected, "\(title) should be selected")
        }
        tabButton(app, "Cari Rute").tap()
        XCTAssertTrue(app.webViews["webView.rute"].waitForExistence(timeout: 10))
        XCTAssertFalse(tabButton(app, "Kalkulator").isSelected)
    }

    func testReselectingTabReturnsHome() {
        let app = launch()
        let webView = app.webViews["webView.kalkulator"]
        let hero = webText(in: webView, containing: "Hitung miles")
        XCTAssertTrue(hero.waitForExistence(timeout: 45))
        webView.links.matching(NSPredicate(format: "label CONTAINS[c] %@", "kalkulator lengkap")).firstMatch.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: hero)
        wait(for: [gone], timeout: 30)
        tabButton(app, "Kalkulator").tap()
        XCTAssertTrue(hero.waitForExistence(timeout: 30), "Re-tapping the selected tab should return to its start page")
    }

    func testSwipeFromLeftEdgeGoesBack() {
        let app = launch()
        let webView = app.webViews["webView.kalkulator"]
        let hero = webText(in: webView, containing: "Hitung miles")
        XCTAssertTrue(hero.waitForExistence(timeout: 45))
        webView.links.matching(NSPredicate(format: "label CONTAINS[c] %@", "kalkulator lengkap")).firstMatch.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: hero)
        wait(for: [gone], timeout: 30)
        let start = webView.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 300, dy: 0)))
        XCTAssertTrue(hero.waitForExistence(timeout: 30), "Swiping from the left edge should go back")
    }

    func testUnreachableShowsErrorAndRetry() {
        let app = launch(["-UITestUnreachable"])
        let errorView = app.descendants(matching: .any)["errorView"]
        XCTAssertTrue(errorView.waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Tidak dapat terhubung"].exists)
        let retry = app.buttons["retryButton"]
        XCTAssertTrue(retry.exists)
        retry.tap()
        XCTAssertTrue(errorView.waitForExistence(timeout: 20), "Error view should come back after a failed retry")
    }
}
