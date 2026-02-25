import Foundation

enum NotificationCategoryID {
    static let prayerAlert = "CHANNEL_PRAYER_ALERT"
    static let prayerAlarm = "CHANNEL_PRAYER_ALARM"
    static let hadithDaily = "CHANNEL_HADITH_DAILY"
    static let hadithNearPrayer = "CHANNEL_HADITH_NEAR_PRAYER"
}

enum NotificationActionID {
    static let snooze = "ACTION_SNOOZE_5_MIN"
    static let dismiss = "ACTION_DISMISS"
    static let hadithOpen = "ACTION_HADITH_OPEN"
    static let hadithSave = "ACTION_HADITH_SAVE"
}

enum NotificationUserInfoKey {
    static let payloadKind = "payloadKind"
    static let prayerName = "prayerName"
    static let fireDate = "fireDate"
    static let hadithID = "hadithID"
    static let hadithBookID = "hadithBookID"
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
