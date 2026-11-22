# BUDAKMILES iOS app

One iOS app for [budakmiles.id](https://budakmiles.id) and [rute.budakmiles.id](https://rute.budakmiles.id), built with SwiftUI and `WKWebView`.

| Tab | Opens |
| --- | --- |
| Kalkulator | https://budakmiles.id/ |
| Cari Rute | https://rute.budakmiles.id/ |
| Tersimpan | https://rute.budakmiles.id/#tersimpan |
| Miles Saya | https://rute.budakmiles.id/tukar-miles |

- Each tab keeps its own page; tapping the selected tab again goes back to its start page.
- A link to the other site switches to the matching tab (Cari Rute, Tersimpan or Miles Saya for rute links, Kalkulator for budakmiles.id links) instead of loading it in the wrong one (`LinkRouter`).
- The sites' own bottom menu is hidden inside the app, since the native tab bar replaces it.
- The seats.aero login for Rute completes inside the app; all tabs share cookies, so the login holds everywhere.
- Other websites, `mailto:`, `tel:` and Telegram/Instagram links open outside the app.
- Pull to refresh, swipe back/forward, a loading bar, and an offline screen with "Coba lagi".
- The user agent ends with `BudakMilesApp/1.0 (iOS)`, so the sites can tell they run inside the app.

## Develop

Requires Xcode 16+ (tested with Xcode 26.6). The project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen); the generated `BudakMiles.xcodeproj` is committed, so XcodeGen is only needed after editing `project.yml` (`brew install xcodegen && xcodegen generate`).

```sh
cd ios
open BudakMiles.xcodeproj
# or run every unit and UI test from the shell:
xcodebuild test -project BudakMiles.xcodeproj -scheme BudakMiles \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

The UI tests load the live sites, so they need internet access. `-UITestUnreachable` points every tab at a host that never resolves to test the offline screen.

## Install a test build

**Simulator (available now):** `./scripts/build_simulator_app.sh` writes `build/BudakMiles-simulator.zip`; CI attaches the same zip to every run of the `iOS` workflow. Unzip it, then `xcrun simctl install booted BudakMiles.app`.

**iPhone via TestFlight (needs Apple access):** run the `iOS TestFlight` workflow from the Actions tab once the items below exist.

## What a person has to provide or approve

1. An [Apple Developer Program](https://developer.apple.com/programs/) membership (USD 99/year) for the account that will own the app.
2. An app record in [App Store Connect](https://appstoreconnect.apple.com) with bundle ID `id.budakmiles.app` (register the ID under Certificates, Identifiers & Profiles first).
3. An App Store Connect API key (role App Manager) saved as GitHub repository secrets: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8` (the `.p8` file contents) and `APPLE_TEAM_ID`.
4. TestFlight testers: internal testers can install right after upload; external testers need Apple's Beta App Review.
5. For the App Store: privacy details, screenshots, and App Review. Apps that mainly show a website can be rejected under [Guideline 4.2 (Minimum Functionality)](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality); the native tabs and offline handling help, but Apple may ask for more native features (e.g. push notifications for saved routes).
