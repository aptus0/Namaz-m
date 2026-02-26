import Foundation
import SwiftUI
import WidgetKit

struct WidgetPrayerSnapshotPayload: Codable {
    struct DayEntry: Codable, Hashable {
        let prayerName: String
        let prayerDate: Date
    }

    let cityName: String
    let prayerName: String
    let nextPrayerDate: Date
    let previousPrayerDate: Date
    let dayEntries: [DayEntry]
    let hadithSnippet: String
    let hadithSource: String
    let premiumThemePack: String
    let accentOption: String
    let refreshDates: [Date]
    let generatedAt: Date

    static var placeholder: WidgetPrayerSnapshotPayload {
        WidgetPrayerSnapshotPayload(
            cityName: "İstanbul",
            prayerName: "Akşam",
            nextPrayerDate: Date().addingTimeInterval(45 * 60),
            previousPrayerDate: Date().addingTimeInterval(-2 * 60 * 60),
            dayEntries: [
                DayEntry(prayerName: "İmsak", prayerDate: Date().addingTimeInterval(-4 * 60 * 60)),
                DayEntry(prayerName: "Güneş", prayerDate: Date().addingTimeInterval(-3 * 60 * 60)),
                DayEntry(prayerName: "Öğle", prayerDate: Date().addingTimeInterval(-30 * 60)),
                DayEntry(prayerName: "İkindi", prayerDate: Date().addingTimeInterval(2 * 60 * 60)),
                DayEntry(prayerName: "Akşam", prayerDate: Date().addingTimeInterval(45 * 60)),
                DayEntry(prayerName: "Yatsı", prayerDate: Date().addingTimeInterval(3 * 60 * 60))
            ],
            hadithSnippet: "Allah katında amellerin en sevimlisi, az da olsa devamlı olanıdır.",
            hadithSource: "Buhari, Rikak 18",
            premiumThemePack: "Klasik Lacivert",
            accentOption: "Lacivert",
            refreshDates: [Date().addingTimeInterval(15 * 60), Date().addingTimeInterval(60 * 60)],
            generatedAt: Date()
        )
    }
}

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPrayerSnapshotPayload
}

enum WidgetPayloadStore {
    private static let payloadKey = "widget.prayer.snapshot.v1"

    static func loadPayload() -> WidgetPrayerSnapshotPayload {
        let defaults = sharedDefaults() ?? .standard
        guard
            let data = defaults.data(forKey: payloadKey),
            let payload = try? JSONDecoder().decode(WidgetPrayerSnapshotPayload.self, from: data)
        else {
            return .placeholder
        }

        return payload
    }

    private static func sharedDefaults() -> UserDefaults? {
        let group = (Bundle.main.object(forInfoDictionaryKey: "WidgetAppGroupID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let group, !group.isEmpty else {
            return nil
        }
        return UserDefaults(suiteName: group)
    }
}

struct WidgetTheme {
    let backgroundTop: Color
    let backgroundBottom: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let gold: Color

    static func resolve(themePack: String, accentOption: String, colorScheme: ColorScheme) -> WidgetTheme {
        let lowered = themePack.lowercased()
        let accent = resolveAccent(accentOption)

        if lowered.contains("ramazan") || lowered.contains("gold") {
            return WidgetTheme(
                backgroundTop: colorScheme == .dark ? Color(red: 0.16, green: 0.12, blue: 0.08) : Color(red: 0.98, green: 0.94, blue: 0.82),
                backgroundBottom: colorScheme == .dark ? Color(red: 0.10, green: 0.08, blue: 0.06) : Color(red: 0.93, green: 0.86, blue: 0.66),
                cardBackground: colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.78),
                textPrimary: colorScheme == .dark ? .white : Color(red: 0.28, green: 0.21, blue: 0.12),
                textSecondary: colorScheme == .dark ? .white.opacity(0.74) : Color(red: 0.45, green: 0.36, blue: 0.18),
                accent: accent,
                gold: Color(red: 0.92, green: 0.76, blue: 0.34)
            )
        }

        if lowered.contains("emerald") || lowered.contains("doga") || lowered.contains("yeşil") {
            return WidgetTheme(
                backgroundTop: colorScheme == .dark ? Color(red: 0.06, green: 0.16, blue: 0.14) : Color(red: 0.86, green: 0.95, blue: 0.90),
                backgroundBottom: colorScheme == .dark ? Color(red: 0.04, green: 0.10, blue: 0.09) : Color(red: 0.76, green: 0.90, blue: 0.83),
                cardBackground: colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.74),
                textPrimary: colorScheme == .dark ? .white : Color(red: 0.10, green: 0.23, blue: 0.20),
                textSecondary: colorScheme == .dark ? .white.opacity(0.72) : Color(red: 0.24, green: 0.40, blue: 0.34),
                accent: accent,
                gold: Color(red: 0.84, green: 0.72, blue: 0.30)
            )
        }

        if lowered.contains("night") || lowered.contains("siyah") {
            return WidgetTheme(
                backgroundTop: Color(red: 0.08, green: 0.09, blue: 0.13),
                backgroundBottom: Color(red: 0.05, green: 0.06, blue: 0.09),
                cardBackground: Color.white.opacity(0.09),
                textPrimary: .white,
                textSecondary: .white.opacity(0.72),
                accent: accent,
                gold: Color(red: 0.90, green: 0.74, blue: 0.35)
            )
        }

        return WidgetTheme(
            backgroundTop: colorScheme == .dark ? Color(red: 0.08, green: 0.15, blue: 0.29) : Color(red: 0.90, green: 0.94, blue: 0.99),
            backgroundBottom: colorScheme == .dark ? Color(red: 0.06, green: 0.10, blue: 0.20) : Color(red: 0.81, green: 0.88, blue: 0.98),
            cardBackground: colorScheme == .dark ? Color.white.opacity(0.11) : Color.white.opacity(0.78),
            textPrimary: colorScheme == .dark ? .white : Color(red: 0.11, green: 0.18, blue: 0.33),
            textSecondary: colorScheme == .dark ? .white.opacity(0.74) : Color(red: 0.28, green: 0.37, blue: 0.54),
            accent: accent,
            gold: Color(red: 0.88, green: 0.72, blue: 0.30)
        )
    }

    private static func resolveAccent(_ value: String) -> Color {
        let lowered = value.lowercased()
        if lowered.contains("altın") || lowered.contains("gold") {
            return Color(red: 0.88, green: 0.68, blue: 0.20)
        }
        if lowered.contains("yeşil") || lowered.contains("teal") || lowered.contains("green") {
            return Color(red: 0.20, green: 0.66, blue: 0.50)
        }
        return Color(red: 0.10, green: 0.34, blue: 0.91)
    }
}
