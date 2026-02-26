import SwiftUI
import AVFoundation
import AudioToolbox
import Combine

struct NotificationSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager
    @StateObject private var soundPreviewPlayer = NotificationSoundPreviewPlayer()

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
                        notificationManager.sendTestNotification(using: appState, tone: appState.generalNotificationTone)
                    } label: {
                        Label("Secili sesle test gonder", systemImage: "paperplane.fill")
                    }
                }
            }

            Section("Bildirim Sesi") {
                Picker("Genel ses", selection: $appState.generalNotificationTone) {
                    ForEach(AlarmTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        soundPreviewPlayer.play(tone: appState.generalNotificationTone)
                    } label: {
                        Label(soundPreviewPlayer.isPlaying ? "Yeniden Oynat" : "Onizleme", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        notificationManager.sendTestNotification(using: appState, tone: appState.generalNotificationTone)
                    } label: {
                        Label("Test Bildirimi", systemImage: "bell.badge.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("Namaz yaklasma, hadis ve test bildirimlerinde secili genel ses kullanilir.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Hadis Bildirimleri") {
                Toggle("Gunluk hadis bildirimi", isOn: $appState.hadithDailyEnabled)

                if appState.hadithDailyEnabled {
                    DatePicker("Saat", selection: $appState.hadithDailyTime, displayedComponents: .hourAndMinute)
                }

                Toggle("Namaz oncesi hadis", isOn: $appState.hadithNearPrayerEnabled)

                Picker("Varsayilan kitap", selection: defaultHadithBookBinding) {
                    Text("One Cikan Koleksiyon").tag("featured")
                    ForEach(appState.hadithBooks) { book in
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

            Section("Canli Vakit ve Widget") {
                Toggle("Kilit ekraninda canli vakit", isOn: $appState.livePrayerActivityEnabled)
                    .onChange(of: appState.livePrayerActivityEnabled) { _, _ in
                        Task {
                            await PrayerLiveActivityService.sync(using: appState)
                        }
                    }

                HStack {
                    Text("Live Activity durumu")
                    Spacer()
                    Text(PrayerLiveActivityService.statusDescription(isEnabledByUser: appState.livePrayerActivityEnabled))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                Button {
                    WidgetSyncService.sync(using: appState)
                } label: {
                    Label("Widgetleri yenile", systemImage: "arrow.clockwise.circle")
                }
            }
        }
        .navigationTitle("Bildirim Ayarlari")
        .onDisappear {
            soundPreviewPlayer.stop()
        }
    }
}

private struct PrayerNotificationSettingCard: View {
    @EnvironmentObject private var appState: AppState
    @Binding var setting: PrayerReminderSetting

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Toggle(setting.prayer.localizedTitle(language: appState.language), isOn: $setting.isEnabled)
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

@MainActor
private final class NotificationSoundPreviewPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    private var player: AVAudioPlayer?

    func play(tone: AlarmTone) {
        stop()

        guard let fileName = tone.fileName else {
            AudioServicesPlaySystemSound(1007)
            return
        }

        guard let url = NotificationToneFileResolver.url(for: fileName) else {
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            player = audioPlayer
            isPlaying = true

            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    self?.isPlaying = false
                }
            }
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}
