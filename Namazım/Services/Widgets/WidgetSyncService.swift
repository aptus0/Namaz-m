import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetPrayerSnapshotPayload: Codable {
    struct DayEntry: Codable {
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
}

@MainActor
enum WidgetSyncService {
    static let payloadKey = "widget.prayer.snapshot.v1"
    static let refreshDatesKey = "widget.prayer.refresh.dates.v1"

    static func sync(using state: AppState, now: Date = Date()) {
        let timeline = currentTimeline(using: state, now: now)
        let entries = currentEntries(using: state, now: now)
        let hadithSelection = state.dailyHadithSelection(for: now)
        let refreshDates = recommendedRefreshDates(from: entries, now: now, timeline: timeline)
        let payload = WidgetPrayerSnapshotPayload(
            cityName: state.selectedCity,
            prayerName: timeline.next.prayer.localizedTitle(language: state.language),
            nextPrayerDate: timeline.next.date,
            previousPrayerDate: timeline.previous.date,
            dayEntries: entries.map {
                WidgetPrayerSnapshotPayload.DayEntry(
                    prayerName: $0.prayer.localizedTitle(language: state.language),
                    prayerDate: $0.date
                )
            },
            hadithSnippet: state.hadithSnippet(for: hadithSelection.hadith, maxLength: 120),
            hadithSource: hadithSelection.hadith.source,
            premiumThemePack: state.premiumThemePack.rawValue,
            accentOption: state.accent.rawValue,
            refreshDates: refreshDates,
            generatedAt: now
        )

        guard let data = try? JSONEncoder().encode(payload) else {
            return
        }

        if let sharedDefaults = sharedDefaults() {
            sharedDefaults.set(data, forKey: payloadKey)
            if let refreshData = try? JSONEncoder().encode(refreshDates) {
                sharedDefaults.set(refreshData, forKey: refreshDatesKey)
            }
        } else {
            UserDefaults.standard.set(data, forKey: payloadKey)
            if let refreshData = try? JSONEncoder().encode(refreshDates) {
                UserDefaults.standard.set(refreshData, forKey: refreshDatesKey)
            }
        }

        reloadAllTimelines()
    }

    static func reloadAllTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private static func currentTimeline(using state: AppState, now: Date) -> PrayerTimeline {
        let selected = normalize(state.selectedCity)
        if let city = WorldCityCatalog.all.first(where: { normalize($0.name) == selected }) {
            return SolarPrayerTimeService.timeline(for: city, now: now)
        }

        return PrayerScheduleProvider.timeline(now: now)
    }

    private static func currentEntries(using state: AppState, now: Date) -> [PrayerEntry] {
        let selected = normalize(state.selectedCity)
        if let city = WorldCityCatalog.all.first(where: { normalize($0.name) == selected }) {
            return SolarPrayerTimeService.entries(for: city, day: now)
        }

        return PrayerScheduleProvider.entries(for: now)
    }

    private static func recommendedRefreshDates(
        from entries: [PrayerEntry],
        now: Date,
        timeline: PrayerTimeline
    ) -> [Date] {
        let upcoming = entries
            .filter { $0.date > now }
            .map(\.date)

        var dates = [timeline.next.date]
        dates.append(contentsOf: upcoming.prefix(3))
        dates.append(now.addingTimeInterval(30 * 60))
        dates.append(now.addingTimeInterval(60 * 60))

        return Array(Set(dates)).sorted()
    }

    private static func sharedDefaults() -> UserDefaults? {
        let suiteName = (Bundle.main.object(forInfoDictionaryKey: "WidgetAppGroupID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let suiteName, !suiteName.isEmpty else {
            return nil
        }

        return UserDefaults(suiteName: suiteName)
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }
}
