import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
struct PrayerLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var cityName: String
        var nextPrayerName: String
        var nextPrayerDate: Date
        var previousPrayerDate: Date
        var updatedAt: Date
    }

    var kind: String
}
#endif

@MainActor
enum PrayerLiveActivityService {
    static func sync(using state: AppState, now: Date = Date()) async {
        guard isFeatureAvailable else { return }

        guard state.livePrayerActivityEnabled else {
            await endAll(reason: "User disabled live prayer")
            return
        }

        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *), ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let snapshot = currentSnapshot(using: state, now: now)
        let contentState = PrayerLiveActivityAttributes.ContentState(
            cityName: snapshot.cityName,
            nextPrayerName: snapshot.timeline.next.prayer.localizedTitle(language: state.language),
            nextPrayerDate: snapshot.timeline.next.date,
            previousPrayerDate: snapshot.timeline.previous.date,
            updatedAt: now
        )

        let content = ActivityContent(
            state: contentState,
            staleDate: snapshot.timeline.next.date.addingTimeInterval(120)
        )

        if let existing = Activity<PrayerLiveActivityAttributes>.activities.first {
            await existing.update(content)
        } else {
            do {
                _ = try Activity<PrayerLiveActivityAttributes>.request(
                    attributes: PrayerLiveActivityAttributes(kind: "next-prayer"),
                    content: content,
                    pushType: nil
                )
            } catch {
                print("Live activity start error: \(error)")
            }
        }
        #endif
    }

    static func endAll(reason: String = "Ended") async {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let finishedState = PrayerLiveActivityAttributes.ContentState(
                cityName: "",
                nextPrayerName: "",
                nextPrayerDate: Date(),
                previousPrayerDate: Date(),
                updatedAt: Date()
            )

            let content = ActivityContent(state: finishedState, staleDate: Date())

            for activity in Activity<PrayerLiveActivityAttributes>.activities {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
        #endif

        _ = reason
    }

    static func statusDescription(isEnabledByUser: Bool) -> String {
        guard isFeatureAvailable else {
            return "Live Activity iOS 16.2+ cihazlarda kullanılabilir."
        }

        guard isEnabledByUser else {
            return "Canlı vakit kapalı."
        }

        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
                ? "Canlı vakit etkin."
                : "Canlı aktiviteler sistem ayarlarından kapalı."
        }
        #endif

        return "Live Activity desteklenmiyor."
    }

    static var isFeatureAvailable: Bool {
        if #available(iOS 16.2, *) {
            return true
        }

        return false
    }

    private static func currentSnapshot(using state: AppState, now: Date) -> (cityName: String, timeline: PrayerTimeline) {
        let selected = normalize(state.selectedCity)

        if let city = WorldCityCatalog.all.first(where: { normalize($0.name) == selected }) {
            return (city.name, SolarPrayerTimeService.timeline(for: city, now: now))
        }

        return (state.selectedCity, PrayerScheduleProvider.timeline(now: now))
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }
}
