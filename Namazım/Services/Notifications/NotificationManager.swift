import Foundation
import Combine
import UIKit
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var activeAlarm: AlarmEvent?

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
    }

    func sendTestNotification(using state: AppState) {
        let prayer = state.prayerSettings.first(where: { $0.isEnabled })?.prayer ?? .aksam

        let content = UNMutableNotificationContent()
        content.title = "Test Bildirimi"
        content.body = "\(prayer.title) icin test bildirimi basariyla hazir."
        content.sound = .default
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
            return "Izin bekleniyor"
        case .denied:
            return "Bildirim izni kapali"
        case .authorized:
            return "Bildirim izni acik"
        case .provisional:
            return "Gecici izin acik"
        case .ephemeral:
            return "Ephemeral izin acik"
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

        let prayerAlert = UNNotificationCategory(
            identifier: NotificationCategoryID.prayerAlert,
            actions: [],
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
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let hadithNearPrayer = UNNotificationCategory(
            identifier: NotificationCategoryID.hadithNearPrayer,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([prayerAlert, prayerAlarm, hadithDaily, hadithNearPrayer])
    }

    private func scheduleSnooze(for event: AlarmEvent) {
        let fireDate = Date().addingTimeInterval(5 * 60)

        let content = UNMutableNotificationContent()
        content.title = "\(event.prayer.title) icin erteleme bitti"
        content.body = "Namaz vaktiniz bekliyor."
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
        if notification.request.content.categoryIdentifier == "CHANNEL_PRAYER_ALARM" {
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

            default:
                if categoryID == "CHANNEL_PRAYER_ALARM", let payload {
                    self.activeAlarm = AlarmEvent(
                        id: response.notification.request.identifier,
                        prayer: payload.prayer,
                        fireDate: payload.fireDate
                    )
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
}
