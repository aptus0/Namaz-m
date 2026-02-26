import Foundation

enum NotificationCategoryID {
    nonisolated static let prayerAlert = "CHANNEL_PRAYER_ALERT"
    nonisolated static let prayerAlarm = "CHANNEL_PRAYER_ALARM"
    nonisolated static let hadithDaily = "CHANNEL_HADITH_DAILY"
    nonisolated static let hadithNearPrayer = "CHANNEL_HADITH_NEAR_PRAYER"
}

enum NotificationActionID {
    nonisolated static let snooze = "ACTION_SNOOZE_5_MIN"
    nonisolated static let dismiss = "ACTION_DISMISS"
    nonisolated static let openApp = "ACTION_OPEN_APP"
    nonisolated static let hadithOpen = "ACTION_HADITH_OPEN"
    nonisolated static let hadithSave = "ACTION_HADITH_SAVE"
}

enum NotificationUserInfoKey {
    nonisolated static let payloadKind = "payloadKind"
    nonisolated static let prayerName = "prayerName"
    nonisolated static let fireDate = "fireDate"
    nonisolated static let hadithID = "hadithID"
    nonisolated static let hadithBookID = "hadithBookID"
}

enum NotificationPayloadKind: String {
    case prayerReminder
    case prayerAlarm
    case hadithDaily
    case hadithNearPrayer
}

struct HadithDeepLink: Equatable, Sendable {
    let bookID: String
    let hadithID: String
}

enum NotificationToneFileResolver {
    static func url(for fileName: String, in bundle: Bundle = .main) -> URL? {
        let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            return nil
        }

        if let direct = bundle.url(forResource: parts[0], withExtension: parts[1]) {
            return direct
        }

        guard let resourceURL = bundle.resourceURL else {
            return nil
        }

        let candidate = resourceURL.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }

        return nil
    }
}
