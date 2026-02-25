import SwiftUI

struct SettingsScreenView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var isCityPickerPresented = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Il Ayari") {
                    Button {
                        isCityPickerPresented = true
                    } label: {
                        HStack {
                            Label("Secili Il", systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(appState.selectedCity)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

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
                }

                Section("Tema ve Veri") {
                    Picker("Tema", selection: $appState.theme) {
                        ForEach(ThemeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Aksan rengi", selection: $appState.accent) {
                        ForEach(AccentOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    Picker("Veri kaynagi", selection: $appState.dataSource) {
                        ForEach(DataSourceOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section("Guclu Calisma Ayarlari") {
                    HStack {
                        Text("Izin durumu")
                        Spacer()
                        Text(notificationManager.statusTitle)
                            .foregroundStyle(.secondary)
                    }

                    Button("Bildirim izinlerini ac") {
                        notificationManager.openNotificationSettings()
                    }

                    Button("Uygulama ayarlarini ac") {
                        notificationManager.openAppSettings()
                    }

                    Text("Bildirimlerin kacmamasi icin bildirim izni ve arka plan ayarlarinin acik olmasi onerilir.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Hakkinda") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("Uygulama Bilgisi", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Ayarlar")
        }
        .sheet(isPresented: $isCityPickerPresented) {
            CityPickerSheet()
                .environmentObject(appState)
        }
    }
}

private struct PrayerNotificationSettingCard: View {
    @Binding var setting: PrayerReminderSetting

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(setting.prayer.title, isOn: $setting.isEnabled)

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

private struct AboutView: View {
    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.2"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section("Uygulama") {
                LabeledContent("Surum", value: appVersionText)
                LabeledContent("Veri Kaynagi", value: "Diyanet / Alternatif")
            }

            Section("Not") {
                Text("Alarm benzeri akis iOS kisitlari dahilinde bildirim + acilisla uygulanmistir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Hakkinda")
    }
}
