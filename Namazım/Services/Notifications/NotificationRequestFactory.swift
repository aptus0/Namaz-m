import Foundation
import UserNotifications

enum NotificationRequestFactory {
    private static let prayerPlanningDays = 2
    private static let hadithPlanningDays = 2

    @MainActor
    static func makeRequests(using state: AppState, now: Date = Date()) -> [UNNotificationRequest] {
        var requests: [UNNotificationRequest] = []

        if state.prayerNotificationsEnabled {
            let days = nextNDays(from: now, count: prayerPlanningDays)
            for day in days {
                let entries = entries(for: day, state: state)

                for setting in state.prayerSettings where setting.isEnabled {
                    guard let entry = entries.first(where: { $0.prayer == setting.prayer }) else {
                        continue
                    }

                    if setting.leadTime.rawValue > 0 {
                        let preDate = entry.date.addingTimeInterval(TimeInterval(-setting.leadTime.rawValue * 60))
                        if preDate > now {
                            let reminderContent = prayerReminderContent(setting: setting, fireDate: preDate, state: state)
                            requests.append(makeRequest(
                                id: "prayer-reminder-\(setting.prayer.rawValue)-\(Int(preDate.timeIntervalSince1970))",
                                date: preDate,
                                content: reminderContent
                            ))

                            if state.hadithNearPrayerEnabled {
                                let hadithDate = preDate.addingTimeInterval(30)
                                if hadithDate > now {
                                    let hadithContent = hadithNearPrayerContent(
                                        prayer: setting.prayer,
                                        fireDate: hadithDate,
                                        state: state
                                    )
                                    requests.append(makeRequest(
                                        id: "hadith-near-prayer-\(setting.prayer.rawValue)-\(Int(hadithDate.timeIntervalSince1970))",
                                        date: hadithDate,
                                        content: hadithContent
                                    ))
                                }
                            }
                        }
                    }

                    if entry.date > now {
                        let atPrayerContent = prayerEntryContent(setting: setting, fireDate: entry.date, state: state)
                        requests.append(makeRequest(
                            id: "prayer-entry-\(setting.prayer.rawValue)-\(Int(entry.date.timeIntervalSince1970))",
                            date: entry.date,
                            content: atPrayerContent
                        ))
                    }
                }
            }
        }

        if state.hadithDailyEnabled {
            requests.append(contentsOf: dailyHadithRequests(time: state.hadithDailyTime, state: state, now: now, days: hadithPlanningDays))
        }

        return requests
    }

    private static func dailyHadithRequests(
        time: Date,
        state: AppState,
        now: Date,
        days: Int
    ) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        return (0..<days).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let fireDate = calendar.date(
                    bySettingHour: timeComponents.hour ?? 9,
                    minute: timeComponents.minute ?? 0,
                    second: 0,
                    of: day
                  ),
                  fireDate > now
            else {
                return nil
            }

            let selection = state.dailyHadithSelection(for: fireDate)
            let body = state.hadithSnippet(for: selection.hadith, maxLength: 110)

            let content = UNMutableNotificationContent()
            content.title = state.localized("app_name")
            content.subtitle = state.localized("notification_daily_hadith_title")
            content.body = body
            content.sound = notificationSound(for: state.generalNotificationTone)
            content.categoryIdentifier = NotificationCategoryID.hadithDaily
            content.threadIdentifier = "hadith-daily"
            content.userInfo = [
                NotificationUserInfoKey.payloadKind: NotificationPayloadKind.hadithDaily.rawValue,
                NotificationUserInfoKey.hadithID: selection.hadith.id,
                NotificationUserInfoKey.hadithBookID: selection.book.id
            ]

            if #available(iOS 15.0, *) {
                content.interruptionLevel = .active
                content.relevanceScore = 0.7
            }

            return makeRequest(
                id: "hadith-daily-\(Int(fireDate.timeIntervalSince1970))",
                date: fireDate,
                content: content
            )
        }
    }

    @MainActor
    private static func prayerReminderContent(
        setting: PrayerReminderSetting,
        fireDate: Date,
        state: AppState
    ) -> UNMutableNotificationContent {
        let prayerTitle = setting.prayer.localizedTitle(language: state.language)
        let content = UNMutableNotificationContent()
        content.title = state.localized("app_name")
        content.subtitle = state.localized("notification_prayer_reminder_title", prayerTitle, setting.leadTime.rawValue)
        content.body = state.localized("notification_prayer_reminder_body")
        content.sound = notificationSound(for: state.generalNotificationTone)
        content.categoryIdentifier = NotificationCategoryID.prayerAlert
        content.threadIdentifier = "prayer-\(setting.prayer.rawValue)"
        content.userInfo = [
            NotificationUserInfoKey.payloadKind: NotificationPayloadKind.prayerReminder.rawValue,
            NotificationUserInfoKey.prayerName: setting.prayer.rawValue,
            NotificationUserInfoKey.fireDate: fireDate.timeIntervalSince1970
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 0.9
        }

        return content
    }

    @MainActor
    private static func hadithNearPrayerContent(
        prayer: PrayerName,
        fireDate: Date,
        state: AppState
    ) -> UNMutableNotificationContent {
        let shiftedDate = Calendar.current.date(byAdding: .minute, value: prayer.orderIndex * 11, to: fireDate) ?? fireDate
        let selection = state.dailyHadithSelection(for: shiftedDate)
        let prayerTitle = prayer.localizedTitle(language: state.language)

        let content = UNMutableNotificationContent()
        content.title = state.localized("app_name")
        content.subtitle = state.localized("notification_hadith_near_prayer_title", prayerTitle)
        content.body = state.hadithSnippet(for: selection.hadith, maxLength: 100)
        content.sound = notificationSound(for: state.generalNotificationTone)
        content.categoryIdentifier = NotificationCategoryID.hadithNearPrayer
        content.threadIdentifier = "hadith-near-prayer"
        content.userInfo = [
            NotificationUserInfoKey.payloadKind: NotificationPayloadKind.hadithNearPrayer.rawValue,
            NotificationUserInfoKey.prayerName: prayer.rawValue,
            NotificationUserInfoKey.hadithID: selection.hadith.id,
            NotificationUserInfoKey.hadithBookID: selection.book.id
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
            content.relevanceScore = 0.72
        }

        return content
    }

    @MainActor
    private static func prayerEntryContent(
        setting: PrayerReminderSetting,
        fireDate: Date,
        state: AppState
    ) -> UNMutableNotificationContent {
        let prayerTitle = setting.prayer.localizedTitle(language: state.language)
        let content = UNMutableNotificationContent()
        content.title = state.localized("app_name")
        content.subtitle = state.localized("notification_prayer_entry_title", prayerTitle)

        switch setting.mode {
        case .notification:
            content.body = state.localized("notification_prayer_entry_body")
            content.categoryIdentifier = NotificationCategoryID.prayerAlert
        case .alarm:
            content.body = state.localized("notification_prayer_alarm_body")
            content.categoryIdentifier = NotificationCategoryID.prayerAlarm
        }

        let selectedTone = setting.tone == .default ? state.generalNotificationTone : setting.tone
        content.sound = notificationSound(for: selectedTone)
        content.threadIdentifier = "prayer-\(setting.prayer.rawValue)"
        content.userInfo = [
            NotificationUserInfoKey.payloadKind: (setting.mode == .alarm ? NotificationPayloadKind.prayerAlarm : NotificationPayloadKind.prayerReminder).rawValue,
            NotificationUserInfoKey.prayerName: setting.prayer.rawValue,
            NotificationUserInfoKey.fireDate: fireDate.timeIntervalSince1970
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1
        }

        return content
    }

    private static func notificationSound(for tone: AlarmTone) -> UNNotificationSound {
        guard let fileName = tone.fileName else {
            return .default
        }

        if NotificationToneFileResolver.url(for: fileName) != nil {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
        }

        return .default
    }

    private static func makeRequest(id: String, date: Date, content: UNMutableNotificationContent) -> UNNotificationRequest {
        let interval = date.timeIntervalSinceNow
        let trigger: UNNotificationTrigger

        if interval > 0, interval < 60 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    @MainActor
    private static func entries(for day: Date, state: AppState) -> [PrayerEntry] {
        let selected = normalize(state.selectedCity)
        if let city = WorldCityCatalog.all.first(where: { normalize($0.name) == selected }) {
            return SolarPrayerTimeService.entries(for: city, day: day)
        }

        return PrayerScheduleProvider.entries(for: day)
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }
}
