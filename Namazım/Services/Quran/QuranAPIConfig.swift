import Foundation

enum QuranAPIConfig {
    private enum InfoKey {
        static let baseURL = "QURAN_API_BASE_URL"
        static let apiKey = "QURAN_API_KEY"
        static let apiKeyHeader = "QURAN_API_KEY_HEADER"
        static let apiAuthPrefix = "QURAN_API_AUTH_PREFIX"
        static let fontsPath = "QURAN_API_FONTS_PATH"
        static let surahsPath = "QURAN_API_SURAHS_PATH"
        static let ayahsPath = "QURAN_API_AYAHS_PATH"
        static let juzsPath = "QURAN_API_JUZS_PATH"
    }

    static var baseURL: URL? {
        guard let raw = infoString(for: InfoKey.baseURL), !raw.isEmpty else { return nil }
        guard let url = URL(string: raw),
              let scheme = url.scheme,
              !scheme.isEmpty,
              url.host != nil else {
            return nil
        }
        return url
    }

    static var apiKey: String {
        infoString(for: InfoKey.apiKey) ?? ""
    }

    static var apiKeyHeader: String {
        let value = infoString(for: InfoKey.apiKeyHeader) ?? "Authorization"
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var apiAuthPrefix: String {
        let value = infoString(for: InfoKey.apiAuthPrefix) ?? "Bearer"
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var fontsPath: String {
        normalizedPath(infoString(for: InfoKey.fontsPath) ?? "/api/v1/fonts")
    }

    static var surahsPath: String {
        normalizedPath(infoString(for: InfoKey.surahsPath) ?? "/api/v1/chapters")
    }

    static var ayahsPathTemplate: String {
        normalizedPath(infoString(for: InfoKey.ayahsPath) ?? "/api/v1/chapters/{surahId}")
    }

    static var juzsPathTemplate: String {
        normalizedPath(infoString(for: InfoKey.juzsPath) ?? "/api/v1/juz/{juzId}")
    }

    static var isConfigured: Bool {
        baseURL != nil && !apiKey.isEmpty
    }

    static func ayahsPath(surahID: String) -> String {
        ayahsPathTemplate.replacingOccurrences(of: "{surahId}", with: surahID)
    }

    static func juzPath(juzID: Int) -> String {
        juzsPathTemplate
            .replacingOccurrences(of: "{juzId}", with: String(juzID))
            .replacingOccurrences(of: "{juz_id}", with: String(juzID))
    }

    private static func infoString(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("$("), trimmed.hasSuffix(")") {
            return nil
        }
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedPath(_ value: String) -> String {
        if value.hasPrefix("/") { return value }
        return "/\(value)"
    }
}
