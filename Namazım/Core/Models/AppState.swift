import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var selectedCity: String = "Kocaeli"
    @Published var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: Keys.onboardingCompleted)

    @Published var theme: ThemeOption = .system
    @Published var accent: AccentOption = .premiumBlue
    @Published var dataSource: DataSourceOption = .diyanet

    @Published var prayerNotificationsEnabled: Bool = true
    @Published var prayerSettings: [PrayerReminderSetting] = PrayerReminderSetting.defaults

    @Published var hadithDailyEnabled: Bool = true
    @Published var hadithDailyTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var hadithNearPrayerEnabled: Bool = true

    @Published private(set) var favoriteContentIDs: Set<String> = []

    var cities: [String] {
        TurkishCities.all
    }

    var notificationFingerprint: String {
        let cal = Calendar.current
        let time = cal.dateComponents([.hour, .minute], from: hadithDailyTime)
        let prayerSummary = prayerSettings
            .sorted { $0.prayer.rawValue < $1.prayer.rawValue }
            .map {
                "\($0.prayer.rawValue):\($0.isEnabled ? 1 : 0):\($0.leadTime.rawValue):\($0.mode.rawValue):\($0.tone.rawValue)"
            }
            .joined(separator: "|")

        return [
            selectedCity,
            prayerNotificationsEnabled ? "1" : "0",
            hadithDailyEnabled ? "1" : "0",
            hadithNearPrayerEnabled ? "1" : "0",
            "\(time.hour ?? 0):\(time.minute ?? 0)",
            prayerSummary
        ].joined(separator: "#")
    }

    func isFavorite(_ content: DailyContent) -> Bool {
        favoriteContentIDs.contains(content.id)
    }

    func toggleFavorite(_ content: DailyContent) {
        if favoriteContentIDs.contains(content.id) {
            favoriteContentIDs.remove(content.id)
        } else {
            favoriteContentIDs.insert(content.id)
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Keys.onboardingCompleted)
    }

    func applyDetectedCity(_ city: String?) {
        guard let city, !city.isEmpty else { return }

        let normalizedDetected = normalize(city)
        if let match = cities.first(where: { normalize($0) == normalizedDetected }) {
            selectedCity = match
            return
        }

        if let looseMatch = cities.first(where: { normalize($0).contains(normalizedDetected) || normalizedDetected.contains(normalize($0)) }) {
            selectedCity = looseMatch
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }
}

private enum Keys {
    static let onboardingCompleted = "onboardingCompleted"
}
