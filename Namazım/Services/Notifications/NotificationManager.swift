import Foundation
import Combine
import UIKit
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var activeAlarm: AlarmEvent?
    @Published var pendingHadithDeepLink: HadithDeepLink?
    @Published var pendingHadithSave: HadithDeepLink?

    private let center = UNUserNotificationCenter.current()
    private var isConfigured = false

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        center.delegate = self
        registerCategories()
    }

    func requestAuthorizationIfNeeded() async {
        configureIfNeeded()
        if authorizationStatus == .notDetermined {
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("Notification authorization failed: \(error)")
            }
        }
        await refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func rescheduleAll(using state: AppState) async {
        guard isAuthorized else { return }
        center.removeAllPendingNotificationRequests()

        let requests = NotificationRequestFactory.makeRequests(using: state)
        for request in requests {
            do {
                try await center.add(request)
            } catch {
                print("Notification scheduling error: \(error)")
            }
        }

        WidgetSyncService.sync(using: state)
        await PrayerLiveActivityService.sync(using: state)
    }

    func sendTestNotification(using state: AppState, tone: AlarmTone? = nil) {
        let prayer = state.prayerSettings.first(where: { $0.isEnabled })?.prayer ?? .aksam
        let prayerTitle = prayer.localizedTitle(language: state.language)
        let selectedTone = tone ?? state.generalNotificationTone

        let content = UNMutableNotificationContent()
        content.title = state.localized("notification_test_title")
        content.body = state.localized("notification_test_body", prayerTitle)
        content.sound = notificationSound(for: selectedTone)
        content.categoryIdentifier = NotificationCategoryID.prayerAlert

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        Task {
            do {
                try await center.add(request)
            } catch {
                print("Test notification error: \(error)")
            }
        }
    }

    func notificationSound(for tone: AlarmTone) -> UNNotificationSound {
        guard let fileName = tone.fileName else {
            return .default
        }

        if NotificationToneFileResolver.url(for: fileName) != nil {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
        }
        return .default
    }

    func dismissAlarm() {
        activeAlarm = nil
    }

    func snoozeActiveAlarm() {
        guard let alarm = activeAlarm else { return }
        scheduleSnooze(for: alarm)
        activeAlarm = nil
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func openNotificationSettings() {
        if #available(iOS 16.0, *) {
            guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
            UIApplication.shared.open(url)
        } else {
            openAppSettings()
        }
    }

    var statusTitle: String {
        switch authorizationStatus {
        case .notDetermined:
            return "İzin bekleniyor"
        case .denied:
            return "Bildirim izni kapalı"
        case .authorized:
            return "Bildirim izni açık"
        case .provisional:
            return "Geçici izin açık"
        case .ephemeral:
            return "Ephemeral izin açık"
        @unknown default:
            return "Durum bilinmiyor"
        }
    }

    private var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral
    }

    private func registerCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: NotificationActionID.snooze,
            title: "Ertele 5 dk",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: NotificationActionID.dismiss,
            title: "Kapat",
            options: [.destructive]
        )

        let openAppAction = UNNotificationAction(
            identifier: NotificationActionID.openApp,
            title: "Uygulamayi Ac",
            options: [.foreground]
        )

        let hadithOpenAction = UNNotificationAction(
            identifier: NotificationActionID.hadithOpen,
            title: "Oku",
            options: [.foreground]
        )

        let hadithSaveAction = UNNotificationAction(
            identifier: NotificationActionID.hadithSave,
            title: "Kaydet",
            options: []
        )

        let prayerAlert = UNNotificationCategory(
            identifier: NotificationCategoryID.prayerAlert,
            actions: [openAppAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        let prayerAlarm = UNNotificationCategory(
            identifier: NotificationCategoryID.prayerAlarm,
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let hadithDaily = UNNotificationCategory(
            identifier: NotificationCategoryID.hadithDaily,
            actions: [hadithOpenAction, hadithSaveAction],
            intentIdentifiers: [],
            options: []
        )

        let hadithNearPrayer = UNNotificationCategory(
            identifier: NotificationCategoryID.hadithNearPrayer,
            actions: [hadithOpenAction, hadithSaveAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([prayerAlert, prayerAlarm, hadithDaily, hadithNearPrayer])
    }

    private func scheduleSnooze(for event: AlarmEvent) {
        let fireDate = Date().addingTimeInterval(5 * 60)
        let prayerTitle = Localizer.text("prayer_name_\(event.prayer.rawValue)", language: .system)

        let content = UNMutableNotificationContent()
        content.title = Localizer.text("notification_snooze_title", language: .system, prayerTitle)
        content.body = Localizer.text("notification_snooze_body", language: .system)
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryID.prayerAlarm
        content.userInfo = [
            NotificationUserInfoKey.payloadKind: NotificationPayloadKind.prayerAlarm.rawValue,
            NotificationUserInfoKey.prayerName: event.prayer.rawValue,
            NotificationUserInfoKey.fireDate: fireDate.timeIntervalSince1970
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "snooze-\(event.prayer.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await center.add(request)
            } catch {
                print("Snooze scheduling error: \(error)")
            }
        }
    }

}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.content.categoryIdentifier == NotificationCategoryID.prayerAlarm {
            let payload = Self.extractPayload(from: notification.request.content.userInfo)
            Task { @MainActor in
                if let payload {
                    self.activeAlarm = AlarmEvent(
                        id: notification.request.identifier,
                        prayer: payload.prayer,
                        fireDate: payload.fireDate
                    )
                }
            }
        }

        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let payload = Self.extractPayload(from: response.notification.request.content.userInfo)
        let categoryID = response.notification.request.content.categoryIdentifier

        Task { @MainActor in
            switch response.actionIdentifier {
            case NotificationActionID.snooze:
                if let alarm = self.activeAlarm {
                    self.scheduleSnooze(for: alarm)
                } else {
                    if let payload {
                        let event = AlarmEvent(
                            id: response.notification.request.identifier,
                            prayer: payload.prayer,
                            fireDate: payload.fireDate
                        )
                        self.activeAlarm = event
                        self.scheduleSnooze(for: event)
                    }
                }
                self.activeAlarm = nil

            case NotificationActionID.dismiss:
                self.activeAlarm = nil

            case NotificationActionID.openApp:
                if categoryID == NotificationCategoryID.prayerAlarm, let payload {
                    self.activeAlarm = AlarmEvent(
                        id: response.notification.request.identifier,
                        prayer: payload.prayer,
                        fireDate: payload.fireDate
                    )
                }

            case NotificationActionID.hadithSave:
                if let hadithLink = Self.extractHadithPayload(from: response.notification.request.content.userInfo) {
                    self.pendingHadithSave = hadithLink
                }

            case NotificationActionID.hadithOpen:
                if let hadithLink = Self.extractHadithPayload(from: response.notification.request.content.userInfo) {
                    self.pendingHadithDeepLink = hadithLink
                }

            default:
                if categoryID == NotificationCategoryID.prayerAlarm, let payload {
                    self.activeAlarm = AlarmEvent(
                        id: response.notification.request.identifier,
                        prayer: payload.prayer,
                        fireDate: payload.fireDate
                    )
                } else if categoryID == NotificationCategoryID.hadithDaily || categoryID == NotificationCategoryID.hadithNearPrayer {
                    if let hadithLink = Self.extractHadithPayload(from: response.notification.request.content.userInfo) {
                        self.pendingHadithDeepLink = hadithLink
                    }
                }
            }

            completionHandler()
        }
    }
}

private extension NotificationManager {
    nonisolated struct AlarmPayload: Sendable {
        let prayer: PrayerName
        let fireDate: Date
    }

    nonisolated static func extractPayload(from userInfo: [AnyHashable: Any]) -> AlarmPayload? {
        guard
            let prayerRaw = userInfo[NotificationUserInfoKey.prayerName] as? String,
            let prayer = PrayerName(rawValue: prayerRaw)
        else {
            return nil
        }

        let timestamp = userInfo[NotificationUserInfoKey.fireDate] as? TimeInterval
        let fireDate = timestamp.map(Date.init(timeIntervalSince1970:)) ?? Date()
        return AlarmPayload(prayer: prayer, fireDate: fireDate)
    }

    nonisolated static func extractHadithPayload(from userInfo: [AnyHashable: Any]) -> HadithDeepLink? {
        guard
            let bookID = userInfo[NotificationUserInfoKey.hadithBookID] as? String,
            let hadithID = userInfo[NotificationUserInfoKey.hadithID] as? String
        else {
            return nil
        }

        return HadithDeepLink(bookID: bookID, hadithID: hadithID)
    }
}
