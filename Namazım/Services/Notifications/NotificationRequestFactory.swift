import Foundation
import UserNotifications

enum NotificationRequestFactory {
    @MainActor
    static func makeRequests(using state: AppState, now: Date = Date()) -> [UNNotificationRequest] {
        var requests: [UNNotificationRequest] = []

        if state.prayerNotificationsEnabled {
            let days = nextNDays(from: now, count: 7)
            for day in days {
                let entries = PrayerScheduleProvider.entries(for: day)

                for setting in state.prayerSettings where setting.isEnabled {
                    guard let entry = entries.first(where: { $0.prayer == setting.prayer }) else {
                        continue
                    }

                    if setting.leadTime.rawValue > 0 {
                        let preDate = entry.date.addingTimeInterval(TimeInterval(-setting.leadTime.rawValue * 60))
                        if preDate > now {
                            let reminderContent = prayerReminderContent(setting: setting, fireDate: preDate)
                            requests.append(makeRequest(
                                id: "prayer-reminder-\(setting.prayer.rawValue)-\(Int(preDate.timeIntervalSince1970))",
                                date: preDate,
                                content: reminderContent
                            ))

                            if state.hadithNearPrayerEnabled {
                                let hadithDate = preDate.addingTimeInterval(6)
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
                        let atPrayerContent = prayerEntryContent(setting: setting, fireDate: entry.date)
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
            requests.append(contentsOf: dailyHadithRequests(time: state.hadithDailyTime, state: state, now: now, days: 14))
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
            let body = HadithRepository.shortSnippet(for: selection.hadith, maxLength: 110)

            let content = UNMutableNotificationContent()
            content.title = "Gunun Hadisi"
            content.body = body
            content.sound = .default
            content.categoryIdentifier = NotificationCategoryID.hadithDaily
            content.userInfo = [
                NotificationUserInfoKey.payloadKind: NotificationPayloadKind.hadithDaily.rawValue,
                NotificationUserInfoKey.hadithID: selection.hadith.id,
                NotificationUserInfoKey.hadithBookID: selection.book.id
            ]

            if #available(iOS 15.0, *) {
                content.interruptionLevel = .active
            }

            return makeRequest(
                id: "hadith-daily-\(Int(fireDate.timeIntervalSince1970))",
                date: fireDate,
                content: content
            )
        }
    }

    private static func prayerReminderContent(setting: PrayerReminderSetting, fireDate: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(setting.prayer.title)'a \(setting.leadTime.rawValue) dk kaldi"
        content.body = "Hazirlik icin son adimlar."
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryID.prayerAlert
        content.threadIdentifier = setting.prayer.rawValue
        content.userInfo = [
            NotificationUserInfoKey.payloadKind: NotificationPayloadKind.prayerReminder.rawValue,
            NotificationUserInfoKey.prayerName: setting.prayer.rawValue,
            NotificationUserInfoKey.fireDate: fireDate.timeIntervalSince1970
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
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

        let content = UNMutableNotificationContent()
        content.title = "\(prayer.title) yaklasiyor"
        content.body = HadithRepository.shortSnippet(for: selection.hadith, maxLength: 100)
        content.sound = .default
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
        }

        return content
    }

    private static func prayerEntryContent(setting: PrayerReminderSetting, fireDate: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(setting.prayer.title) vakti girdi"

        switch setting.mode {
        case .notification:
            content.body = "Namaz vaktiniz basladi."
            content.categoryIdentifier = NotificationCategoryID.prayerAlert
        case .alarm:
            content.body = "Alarm modu acik. Ertele veya kapat secenegi hazir."
            content.categoryIdentifier = NotificationCategoryID.prayerAlarm
        }

        content.sound = notificationSound(for: setting.tone)
        content.threadIdentifier = setting.prayer.rawValue
        content.userInfo = [
            NotificationUserInfoKey.payloadKind: (setting.mode == .alarm ? NotificationPayloadKind.prayerAlarm : NotificationPayloadKind.prayerReminder).rawValue,
            NotificationUserInfoKey.prayerName: setting.prayer.rawValue,
            NotificationUserInfoKey.fireDate: fireDate.timeIntervalSince1970
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        return content
    }

    private static func notificationSound(for tone: AlarmTone) -> UNNotificationSound {
        guard let fileName = tone.fileName else {
            return .default
        }

        let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        if parts.count == 2, Bundle.main.url(forResource: parts[0], withExtension: parts[1]) != nil {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
        }

        return .default
    }

    private static func makeRequest(id: String, date: Date, content: UNMutableNotificationContent) -> UNNotificationRequest {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}
