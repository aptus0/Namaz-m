import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager

    private var defaultHadithBookBinding: Binding<String> {
        Binding(
            get: { appState.hadithDefaultBookID ?? "featured" },
            set: { newValue in
                appState.hadithDefaultBookID = (newValue == "featured") ? nil : newValue
            }
        )
    }

    var body: some View {
        Form {
            Section("Namaz Hatirlatici") {
                Toggle("Namaz bildirimleri", isOn: $appState.prayerNotificationsEnabled)

                if appState.prayerNotificationsEnabled {
                    ForEach($appState.prayerSettings) { $setting in
                        PrayerNotificationSettingCard(setting: $setting)
                    }

                    Button {
                        notificationManager.sendTestNotification(using: appState)
                    } label: {
                        Label("Test bildirimi gonder", systemImage: "paperplane.fill")
                    }
                }
            }

            Section("Hadis Bildirimleri") {
                Toggle("Gunluk hadis bildirimi", isOn: $appState.hadithDailyEnabled)

                if appState.hadithDailyEnabled {
                    DatePicker("Saat", selection: $appState.hadithDailyTime, displayedComponents: .hourAndMinute)
                }

                Toggle("Namaz oncesi hadis", isOn: $appState.hadithNearPrayerEnabled)

                Picker("Varsayilan kitap", selection: defaultHadithBookBinding) {
                    Text("One Cikan Koleksiyon").tag("featured")
                    ForEach(HadithRepository.books) { book in
                        Text(book.title).tag(book.id)
                    }
                }
            }

            Section("Izin ve Guclu Calisma") {
                HStack {
                    Text("Bildirim izni")
                    Spacer()
                    Text(notificationManager.statusTitle)
                        .foregroundStyle(.secondary)
                }

                Button("Bildirim ayarlarini ac") {
                    notificationManager.openNotificationSettings()
                }

                Text("Bildirimlerin kacmamasi icin sistem izinlerini acik tutmaniz onerilir.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Bildirim Ayarlari")
    }
}

private struct PrayerNotificationSettingCard: View {
    @Binding var setting: PrayerReminderSetting

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Toggle(setting.prayer.title, isOn: $setting.isEnabled)
                if setting.isEnabled {
                    Text(setting.leadTime.title)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(PremiumPalette.gold.opacity(0.2)))
                }
            }

            if setting.isEnabled {
                Picker("Hatirlatma", selection: $setting.leadTime) {
                    ForEach(ReminderLeadTime.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Picker("Mod", selection: $setting.mode) {
                    ForEach(ReminderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Ses", selection: $setting.tone) {
                    ForEach(AlarmTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
