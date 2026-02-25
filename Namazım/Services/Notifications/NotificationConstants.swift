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
}

enum NotificationUserInfoKey {
    static let payloadKind = "payloadKind"
    static let prayerName = "prayerName"
    static let fireDate = "fireDate"
}

enum NotificationPayloadKind: String {
    case prayerReminder
    case prayerAlarm
    case hadithDaily
    case hadithNearPrayer
}
