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
    @Published var hadithDefaultBookID: String?
    @Published var hadithTextSize: HadithTextSize = .medium
    @Published var hadithReadingModeSimple: Bool = false

    @Published private(set) var hadithFavoriteIDs: Set<String> = []
    @Published private(set) var readingProgressByBookID: [String: String] = [:]

    private let hadithInstallSeed: Int

    init() {
        if let stored = UserDefaults.standard.object(forKey: Keys.hadithInstallSeed) as? Int {
            hadithInstallSeed = stored
        } else {
            let generated = abs(UUID().uuidString.hashValue % 10_000)
            hadithInstallSeed = generated
            UserDefaults.standard.set(generated, forKey: Keys.hadithInstallSeed)
        }
    }

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
            hadithDefaultBookID ?? "featured",
            hadithTextSize.rawValue,
            hadithReadingModeSimple ? "1" : "0",
            prayerSummary
        ].joined(separator: "#")
    }

    var favoriteHadiths: [HadithItem] {
        HadithRepository.hadiths
            .filter { hadithFavoriteIDs.contains($0.id) }
            .sorted { $0.number < $1.number }
    }

    func dailyHadithSelection(for date: Date = Date()) -> HadithDailySelection {
        HadithRepository.dailySelection(
            on: date,
            preferredBookID: hadithDefaultBookID,
            installSeed: hadithInstallSeed
        )
    }

    func isHadithFavorite(_ hadith: HadithItem) -> Bool {
        hadithFavoriteIDs.contains(hadith.id)
    }

    func toggleHadithFavorite(_ hadith: HadithItem) {
        if hadithFavoriteIDs.contains(hadith.id) {
            hadithFavoriteIDs.remove(hadith.id)
        } else {
            hadithFavoriteIDs.insert(hadith.id)
        }
    }

    func markHadithFavorite(_ hadith: HadithItem) {
        hadithFavoriteIDs.insert(hadith.id)
    }

    func saveReadingProgress(bookID: String, hadithID: String) {
        readingProgressByBookID[bookID] = hadithID
    }

    func readingProgress(for bookID: String) -> HadithItem? {
        guard let hadithID = readingProgressByBookID[bookID] else { return nil }
        return HadithRepository.hadith(id: hadithID)
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
    static let hadithInstallSeed = "hadith.installSeed"
}
