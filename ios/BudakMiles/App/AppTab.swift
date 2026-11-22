import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case kalkulator
    case rute
    case tersimpan
    case milesSaya

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kalkulator: return "Kalkulator"
        case .rute: return "Cari Rute"
        case .tersimpan: return "Tersimpan"
        case .milesSaya: return "Miles Saya"
        }
    }

    var systemImage: String {
        switch self {
        case .kalkulator: return "creditcard"
        case .rute: return "airplane"
        case .tersimpan: return "bookmark"
        case .milesSaya: return "wallet.bifold"
        }
    }

    var site: Site {
        self == .kalkulator ? .main : .rute
    }

    var rootURL: URL {
        switch self {
        case .kalkulator: return URL(string: "https://budakmiles.id/")!
        case .rute: return URL(string: "https://rute.budakmiles.id/")!
        case .tersimpan: return URL(string: "https://rute.budakmiles.id/#tersimpan")!
        case .milesSaya: return URL(string: "https://rute.budakmiles.id/tukar-miles")!
        }
    }

    /// The tab that should show a URL of one of the BUDAKMILES sites.
    static func tab(for url: URL) -> AppTab? {
        switch Site(url: url) {
        case .main: return .kalkulator
        case .rute:
            if url.fragment == "tersimpan" { return .tersimpan }
            if url.path.hasPrefix("/tukar-miles") { return .milesSaya }
            return .rute
        case nil: return nil
        }
    }
}

enum Site: Equatable {
    case main
    case rute

    static let mainHost = "budakmiles.id"
    static let ruteHost = "rute.budakmiles.id"

    init?(url: URL) {
        switch LinkRouter.normalizedHost(url) {
        case Site.mainHost: self = .main
        case Site.ruteHost: self = .rute
        default: return nil
        }
    }
}
