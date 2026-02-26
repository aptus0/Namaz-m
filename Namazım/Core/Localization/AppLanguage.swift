import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case tr
    case en
    case ar
    case de

    var id: Self { self }

    nonisolated var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.preferredLanguages.first ?? "tr"
        case .tr:
            return "tr"
        case .en:
            return "en"
        case .ar:
            return "ar"
        case .de:
            return "de"
        }
    }

    nonisolated var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    nonisolated var displayTitle: String {
        switch self {
        case .system:
            return "Sistem"
        case .tr:
            return "Türkçe"
        case .en:
            return "English"
        case .ar:
            return "العربية"
        case .de:
            return "Deutsch"
        }
    }

    nonisolated var isRTL: Bool {
        if #available(iOS 16.0, *) {
            return Locale.Language(identifier: localeIdentifier).characterDirection == .rightToLeft
        }

        return localeIdentifier.hasPrefix("ar")
    }
}

enum Localizer {
    nonisolated static func text(_ key: String, language: AppLanguage) -> String {
        localizedString(for: key, language: language)
    }

    nonisolated static func text(_ key: String, language: AppLanguage, _ args: CVarArg...) -> String {
        let format = localizedString(for: key, language: language)
        return String(format: format, locale: language.locale, arguments: args)
    }

    private nonisolated static func localizedString(for key: String, language: AppLanguage) -> String {
        let candidateCodes: [String]
        if language == .system {
            candidateCodes = systemLanguageCandidates()
        } else {
            candidateCodes = [language.rawValue]
        }

        for code in candidateCodes {
            if let localized = localizedString(for: key, languageCode: code), localized != key {
                return localized
            }
        }

        if let turkish = localizedString(for: key, languageCode: "tr"), turkish != key {
            return turkish
        }

        if let fallback = TurkishFallbackMap.values[key] {
            return fallback
        }

        return Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
    }

    private nonisolated static func localizedString(for key: String, languageCode: String) -> String? {
        guard let bundle = localizedBundle(for: languageCode) else {
            return nil
        }

        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    private nonisolated static func localizedBundle(for languageCode: String) -> Bundle? {
        let baseCode = languageCode
            .split(separator: "-")
            .first
            .map(String.init)
            ?? languageCode

        let folderCandidates = [nil, "Resources/Localization"]
        let codeCandidates = [languageCode, baseCode]
        let bundles = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks

        for bundle in bundles {
            for folder in folderCandidates {
                for code in codeCandidates {
                    if let path = bundle.path(forResource: code, ofType: "lproj", inDirectory: folder),
                       let localized = Bundle(path: path) {
                        return localized
                    }
                }
            }
        }

        return nil
    }

    private nonisolated static func systemLanguageCandidates() -> [String] {
        var candidates: [String] = []
        for preferred in Locale.preferredLanguages {
            let locale = Locale(identifier: preferred)
            if #available(iOS 16.0, *) {
                if let code = locale.language.languageCode?.identifier {
                    candidates.append(code)
                }
            } else {
                candidates.append(preferred)
            }

            candidates.append(preferred)
        }

        candidates.append("tr")
        candidates.append("en")

        var unique: [String] = []
        for candidate in candidates where !unique.contains(candidate) {
            unique.append(candidate)
        }
        return unique
    }
}
