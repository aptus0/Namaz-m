import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class AppState: ObservableObject {
    @Published var selectedCity: String = "Kocaeli"
    @Published var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: Keys.onboardingCompleted)
    @Published var language: AppLanguage = .tr {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
        }
    }
    @Published var premiumThemePack: PremiumThemePack = .classicNavy {
        didSet {
            UserDefaults.standard.set(premiumThemePack.rawValue, forKey: Keys.premiumThemePack)
            applyThemePreset(premiumThemePack)
        }
    }

    @Published var theme: ThemeOption = .system
    @Published var accent: AccentOption = .premiumBlue
    @Published var dataSource: DataSourceOption = .diyanet

    @Published var prayerNotificationsEnabled: Bool = true
    @Published var prayerSettings: [PrayerReminderSetting] = PrayerReminderSetting.defaults
    @Published var generalNotificationTone: AlarmTone = .ezanSoft {
        didSet {
            UserDefaults.standard.set(generalNotificationTone.rawValue, forKey: Keys.generalNotificationTone)
        }
    }
    @Published var livePrayerActivityEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(livePrayerActivityEnabled, forKey: Keys.livePrayerActivityEnabled)
        }
    }
    @Published var selectedAppIconChoice: AppIconChoice = .primary {
        didSet {
            UserDefaults.standard.set(selectedAppIconChoice.rawValue, forKey: Keys.selectedAppIconChoice)
        }
    }
    @Published var worldCityIDs: [String] = WorldCityCatalog.defaultCityIDs {
        didSet {
            UserDefaults.standard.set(worldCityIDs, forKey: Keys.worldCityIDs)
        }
    }

    @Published var hadithDailyEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(hadithDailyEnabled, forKey: Keys.hadithDailyEnabled)
        }
    }
    @Published var hadithDailyTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet {
            UserDefaults.standard.set(hadithDailyTime.timeIntervalSince1970, forKey: Keys.hadithDailyTime)
        }
    }
    @Published var hadithNearPrayerEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(hadithNearPrayerEnabled, forKey: Keys.hadithNearPrayerEnabled)
        }
    }
    @Published var hadithDefaultBookID: String? {
        didSet {
            if let hadithDefaultBookID, !hadithBooks.contains(where: { $0.id == hadithDefaultBookID }) {
                self.hadithDefaultBookID = nil
                return
            }
            UserDefaults.standard.set(hadithDefaultBookID, forKey: Keys.hadithDefaultBookID)
        }
    }
    @Published var hadithSource: HadithSourceOption = .contentPack {
        didSet {
            UserDefaults.standard.set(hadithSource.rawValue, forKey: Keys.hadithSource)
        }
    }
    @Published var hadithTextSize: HadithTextSize = .medium {
        didSet {
            UserDefaults.standard.set(hadithTextSize.rawValue, forKey: Keys.hadithTextSize)
        }
    }
    @Published var hadithReadingModeSimple: Bool = false {
        didSet {
            UserDefaults.standard.set(hadithReadingModeSimple, forKey: Keys.hadithReadingModeSimple)
        }
    }

    @Published private(set) var hadithFavoriteIDs: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(hadithFavoriteIDs), forKey: Keys.hadithFavoriteIDs)
        }
    }
    @Published private(set) var readingProgressByBookID: [String: String] = [:] {
        didSet {
            UserDefaults.standard.set(readingProgressByBookID, forKey: Keys.hadithReadingProgress)
        }
    }
    @Published private(set) var syncedHadithRecords: [HadithRemoteRecord] = []
    @Published private(set) var hadithSyncState: HadithSyncState = .idle
    @Published private(set) var quranFonts: [QuranFont] = []
    @Published private(set) var quranSurahs: [QuranSurah] = []
    @Published private(set) var quranJuzs: [QuranJuz] = []
    @Published private(set) var quranFontSyncState: QuranSyncState = .idle
    @Published private(set) var quranCatalogSyncState: QuranSyncState = .idle
    @Published private(set) var quranFontInstallStateByID: [String: QuranFontInstallState] = [:]
    @Published var selectedQuranFontID: String? {
        didSet {
            UserDefaults.standard.set(selectedQuranFontID, forKey: Keys.selectedQuranFontID)
        }
    }
    @Published var selectedQuranFontPostScriptName: String? {
        didSet {
            UserDefaults.standard.set(selectedQuranFontPostScriptName, forKey: Keys.selectedQuranFontPostScriptName)
        }
    }

    private let hadithInstallSeed: Int

    init() {
        if let stored = UserDefaults.standard.object(forKey: Keys.hadithInstallSeed) as? Int {
            hadithInstallSeed = stored
        } else {
            let generated = abs(UUID().uuidString.hashValue % 10_000)
            hadithInstallSeed = generated
            UserDefaults.standard.set(generated, forKey: Keys.hadithInstallSeed)
        }

        if let restoredLanguageRaw = UserDefaults.standard.string(forKey: Keys.language),
           let restoredLanguage = AppLanguage(rawValue: restoredLanguageRaw) {
            language = restoredLanguage
        } else {
            language = .tr
            UserDefaults.standard.set(AppLanguage.tr.rawValue, forKey: Keys.language)
        }

        if let rawThemePack = UserDefaults.standard.string(forKey: Keys.premiumThemePack),
           let restoredPack = PremiumThemePack(rawValue: rawThemePack) {
            premiumThemePack = restoredPack
        } else {
            applyThemePreset(premiumThemePack)
        }

        if let restoredWorldCityIDs = UserDefaults.standard.array(forKey: Keys.worldCityIDs) as? [String],
           !restoredWorldCityIDs.isEmpty {
            worldCityIDs = restoredWorldCityIDs
        }

        if UserDefaults.standard.object(forKey: Keys.livePrayerActivityEnabled) != nil {
            livePrayerActivityEnabled = UserDefaults.standard.bool(forKey: Keys.livePrayerActivityEnabled)
        }

        if let savedTone = UserDefaults.standard.string(forKey: Keys.generalNotificationTone),
           let restoredTone = AlarmTone(rawValue: savedTone) {
            generalNotificationTone = restoredTone
        }

        if let savedIcon = UserDefaults.standard.string(forKey: Keys.selectedAppIconChoice),
           let restoredIcon = AppIconChoice(rawValue: savedIcon) {
            selectedAppIconChoice = restoredIcon
        }

        if let restoredHadithSource = UserDefaults.standard.string(forKey: Keys.hadithSource),
           let source = HadithSourceOption(rawValue: restoredHadithSource) {
            hadithSource = source
        }

        if UserDefaults.standard.object(forKey: Keys.hadithDailyEnabled) != nil {
            hadithDailyEnabled = UserDefaults.standard.bool(forKey: Keys.hadithDailyEnabled)
        }

        if UserDefaults.standard.object(forKey: Keys.hadithNearPrayerEnabled) != nil {
            hadithNearPrayerEnabled = UserDefaults.standard.bool(forKey: Keys.hadithNearPrayerEnabled)
        }

        if let savedDailyTime = UserDefaults.standard.object(forKey: Keys.hadithDailyTime) as? TimeInterval {
            hadithDailyTime = Date(timeIntervalSince1970: savedDailyTime)
        }

        if let savedDefaultBookID = UserDefaults.standard.string(forKey: Keys.hadithDefaultBookID),
           !savedDefaultBookID.isEmpty {
            hadithDefaultBookID = savedDefaultBookID
        }

        if let savedTextSize = UserDefaults.standard.string(forKey: Keys.hadithTextSize),
           let textSize = HadithTextSize(rawValue: savedTextSize) {
            hadithTextSize = textSize
        }

        if UserDefaults.standard.object(forKey: Keys.hadithReadingModeSimple) != nil {
            hadithReadingModeSimple = UserDefaults.standard.bool(forKey: Keys.hadithReadingModeSimple)
        }

        if let savedFavoriteIDs = UserDefaults.standard.array(forKey: Keys.hadithFavoriteIDs) as? [String] {
            hadithFavoriteIDs = Set(savedFavoriteIDs)
        }

        if let savedReadingProgress = UserDefaults.standard.dictionary(forKey: Keys.hadithReadingProgress) as? [String: String] {
            readingProgressByBookID = savedReadingProgress
        }

        if let savedQuranFontID = UserDefaults.standard.string(forKey: Keys.selectedQuranFontID),
           !savedQuranFontID.isEmpty {
            selectedQuranFontID = savedQuranFontID
        }

        if let savedQuranFontPostScriptName = UserDefaults.standard.string(forKey: Keys.selectedQuranFontPostScriptName),
           !savedQuranFontPostScriptName.isEmpty {
            selectedQuranFontPostScriptName = savedQuranFontPostScriptName
        }

        Task {
            let cached = await HadithSyncService.shared.loadCached()
            if !cached.isEmpty {
                syncedHadithRecords = cached
                hadithSyncState = .synced(count: cached.count, date: Date())
            } else {
                do {
                    let records = try await HadithSyncService.shared.sync(
                        source: hadithSource,
                        language: language
                    )
                    syncedHadithRecords = records
                    hadithSyncState = .synced(count: records.count, date: Date())
                } catch {
                    hadithSyncState = .failed(message: error.localizedDescription)
                }
            }
            sanitizeHadithState()
        }

        Task {
            await QuranSyncService.shared.registerCachedFonts()
            quranFonts = await QuranSyncService.shared.loadCachedFonts()
            quranSurahs = await QuranSyncService.shared.loadCachedSurahs()
            quranJuzs = await QuranSyncService.shared.loadCachedJuzs()
            sanitizeQuranState()
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
            generalNotificationTone.rawValue,
            prayerSummary
        ].joined(separator: "#")
    }

    var hadithCatalog: HadithCatalog {
        HadithCatalog.remote(records: syncedHadithRecords) ?? .localDefault
    }

    var hadithBooks: [HadithBook] {
        hadithCatalog.books
    }

    var featuredHadithBooks: [HadithBook] {
        hadithCatalog.featuredBooks()
    }

    func hadithBook(id: String) -> HadithBook? {
        hadithCatalog.book(id: id)
    }

    func hadithSections(for bookID: String) -> [HadithSection] {
        hadithCatalog.sections(for: bookID)
    }

    func hadithSection(bookID: String, sectionID: String) -> HadithSection? {
        hadithCatalog.section(bookID: bookID, sectionID: sectionID)
    }

    func hadithItems(for bookID: String) -> [HadithItem] {
        hadithCatalog.hadiths(for: bookID)
    }

    func hadithItem(id: String) -> HadithItem? {
        hadithCatalog.hadith(id: id)
    }

    var favoriteHadiths: [HadithItem] {
        hadithCatalog.hadiths
            .filter { hadithFavoriteIDs.contains($0.id) }
            .sorted { $0.number < $1.number }
    }

    func dailyHadithSelection(for date: Date = Date()) -> HadithDailySelection {
        hadithCatalog.dailySelection(
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
        return hadithCatalog.hadith(id: hadithID)
    }

    func hadithSnippet(for hadith: HadithItem, maxLength: Int = 110) -> String {
        let trimmed = hadith.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else {
            return trimmed
        }

        let clipped = trimmed.prefix(max(1, maxLength - 1))
        return "\(clipped)…"
    }

    var quranAPIConfigured: Bool {
        QuranAPIConfig.isConfigured
    }

    var selectedQuranFont: QuranFont? {
        guard let selectedQuranFontID else { return nil }
        return quranFonts.first(where: { $0.id == selectedQuranFontID })
    }

    func quranFontInstallState(for font: QuranFont) -> QuranFontInstallState {
        if let state = quranFontInstallStateByID[font.id] {
            return state
        }
        return font.isDownloaded ? .downloaded : .notDownloaded
    }

    func quranReaderFont(size: CGFloat, fallbackDesign: Font.Design = .rounded) -> Font {
        guard let postScriptName = selectedQuranFontPostScriptName,
              !postScriptName.isEmpty,
              UIFont(name: postScriptName, size: size) != nil else {
            return .system(size: size, weight: .regular, design: fallbackDesign)
        }

        return .custom(postScriptName, size: size)
    }

    func syncQuranFonts() async {
        quranFontSyncState = .syncing

        do {
            let fonts = try await QuranSyncService.shared.syncFonts()
            quranFonts = fonts
            sanitizeQuranState()
            quranFontSyncState = .synced(count: fonts.count, date: Date())
        } catch {
            quranFontSyncState = .failed(message: error.localizedDescription)
        }
    }

    func syncQuranCatalog() async {
        quranCatalogSyncState = .syncing

        do {
            async let surahTask = QuranSyncService.shared.syncSurahs()
            async let juzTask = QuranSyncService.shared.syncJuzs()
            let (surahs, juzs) = try await (surahTask, juzTask)
            quranSurahs = surahs
            quranJuzs = juzs
            quranCatalogSyncState = .synced(count: surahs.count, date: Date())
        } catch {
            quranCatalogSyncState = .failed(message: error.localizedDescription)
        }
    }

    func quranAyahs(for surahID: String, forceRefresh: Bool = false) async -> [QuranAyah] {
        do {
            return try await QuranSyncService.shared.ayahs(for: surahID, forceRefresh: forceRefresh)
        } catch {
            return []
        }
    }

    func installQuranFont(_ font: QuranFont) async {
        quranFontInstallStateByID[font.id] = .downloading

        do {
            let installed = try await QuranSyncService.shared.installFont(id: font.id)
            if let index = quranFonts.firstIndex(where: { $0.id == installed.id }) {
                quranFonts[index] = installed
            } else {
                quranFonts.append(installed)
            }

            quranFontInstallStateByID[font.id] = .downloaded
            selectQuranFont(installed)
        } catch {
            quranFontInstallStateByID[font.id] = .failed(message: error.localizedDescription)
        }
    }

    func selectQuranFont(_ font: QuranFont) {
        selectedQuranFontID = font.id
        selectedQuranFontPostScriptName = font.postScriptName
        quranFontInstallStateByID[font.id] = .downloaded
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

    var selectedWorldCities: [WorldCity] {
        worldCityIDs.compactMap(WorldCityCatalog.city(id:))
    }

    func worldPrayerSnapshots(now: Date = Date()) -> [WorldCityPrayerSnapshot] {
        selectedWorldCities.map { city in
            SolarPrayerTimeService.snapshot(for: city, now: now, language: language)
        }
    }

    func addWorldCity(_ city: WorldCity) {
        guard !worldCityIDs.contains(city.id) else { return }
        worldCityIDs.append(city.id)
    }

    func removeWorldCity(_ city: WorldCity) {
        worldCityIDs.removeAll { $0 == city.id }
    }

    func isWorldCitySelected(_ city: WorldCity) -> Bool {
        worldCityIDs.contains(city.id)
    }

    func syncHadithCatalog() async {
        hadithSyncState = .syncing

        do {
            let records = try await HadithSyncService.shared.sync(
                source: hadithSource,
                language: language
            )
            syncedHadithRecords = records
            sanitizeHadithState()
            hadithSyncState = .synced(count: records.count, date: Date())
        } catch {
            hadithSyncState = .failed(message: error.localizedDescription)
        }
    }

    private func sanitizeHadithState() {
        let catalog = hadithCatalog
        let validBookIDs = Set(catalog.books.map(\.id))
        let validHadithIDs = Set(catalog.hadiths.map(\.id))

        if let hadithDefaultBookID, !validBookIDs.contains(hadithDefaultBookID) {
            self.hadithDefaultBookID = nil
        }

        let filteredFavoriteIDs = hadithFavoriteIDs.intersection(validHadithIDs)
        if filteredFavoriteIDs != hadithFavoriteIDs {
            hadithFavoriteIDs = filteredFavoriteIDs
        }

        let filteredReadingProgress = readingProgressByBookID.filter { key, value in
            validBookIDs.contains(key) && validHadithIDs.contains(value)
        }
        if filteredReadingProgress != readingProgressByBookID {
            readingProgressByBookID = filteredReadingProgress
        }
    }

    private func sanitizeQuranState() {
        let validFontIDs = Set(quranFonts.map(\.id))

        if let selectedQuranFontID, !validFontIDs.contains(selectedQuranFontID) {
            self.selectedQuranFontID = nil
            self.selectedQuranFontPostScriptName = nil
        }

        if let selected = selectedQuranFont {
            if selectedQuranFontPostScriptName?.isEmpty != false,
               let postScriptName = selected.postScriptName,
               !postScriptName.isEmpty {
                selectedQuranFontPostScriptName = postScriptName
            }
        }

        quranFontInstallStateByID = quranFontInstallStateByID.filter { validFontIDs.contains($0.key) }
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }

    private func applyThemePreset(_ pack: PremiumThemePack) {
        switch pack {
        case .classicNavy:
            theme = .system
            accent = .premiumBlue
        case .minimalWhite:
            theme = .light
            accent = .teal
        case .nightBlack:
            theme = .dark
            accent = .premiumBlue
        case .ramadanGold:
            theme = .light
            accent = .warmGold
        case .natureGreen:
            theme = .system
            accent = .teal
        }
    }

    func localized(_ key: String) -> String {
        Localizer.text(key, language: language)
    }

    func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, locale: language.locale, arguments: args)
    }

    var layoutDirection: LayoutDirection {
        language.isRTL ? .rightToLeft : .leftToRight
    }

    func themePalette(for colorScheme: ColorScheme) -> PremiumThemePalette {
        premiumThemePack.palette(for: colorScheme)
    }
}

private enum Keys {
    static let onboardingCompleted = "onboardingCompleted"
    static let hadithInstallSeed = "hadith.installSeed"
    static let language = "app.language"
    static let premiumThemePack = "app.theme.pack"
    static let selectedAppIconChoice = "app.icon.choice"
    static let generalNotificationTone = "notification.generalTone"
    static let worldCityIDs = "world.city.ids"
    static let livePrayerActivityEnabled = "live.prayer.activity.enabled"
    static let hadithSource = "hadith.source"
    static let hadithDailyEnabled = "hadith.daily.enabled"
    static let hadithDailyTime = "hadith.daily.time"
    static let hadithNearPrayerEnabled = "hadith.nearPrayer.enabled"
    static let hadithDefaultBookID = "hadith.defaultBookID"
    static let hadithTextSize = "hadith.textSize"
    static let hadithReadingModeSimple = "hadith.reading.simpleMode"
    static let hadithFavoriteIDs = "hadith.favoriteIDs"
    static let hadithReadingProgress = "hadith.reading.progressByBookID"
    static let selectedQuranFontID = "quran.selectedFontID"
    static let selectedQuranFontPostScriptName = "quran.selectedFontPostScriptName"
}
