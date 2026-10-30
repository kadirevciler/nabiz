import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Identifiable {
    case tr, en
    var id: String { rawValue }
    var name: String { self == .tr ? "Türkçe" : "English" }
    var flag: String { self == .tr ? "TR" : "EN" }
}

/// Uygulama içi dil seçimi. Değişince arayüz anında yenilenir.
@Observable
final class Loc {
    static let shared = Loc()
    var lang: AppLanguage {
        didSet { UserDefaults.standard.set(lang.rawValue, forKey: "language") }
    }
    init() {
        if let saved = UserDefaults.standard.string(forKey: "language"), let l = AppLanguage(rawValue: saved) {
            lang = l
        } else {
            lang = (Locale.preferredLanguages.first ?? "en").hasPrefix("tr") ? .tr : .en
        }
    }
    var locale: Locale { Locale(identifier: lang == .tr ? "tr_TR" : "en_US") }
}

/// Türkçe ve İngilizce metinden geçerli dile uygun olanı döndürür.
func L(_ tr: String, _ en: String) -> String { Loc.shared.lang == .tr ? tr : en }
