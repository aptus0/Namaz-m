import SwiftUI

struct SettingsScreenView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var adManager: AdManager

    @State private var isCityPickerPresented = false

    private var defaultHadithBookBinding: Binding<String> {
        Binding(
            get: { appState.hadithDefaultBookID ?? "featured" },
            set: { newValue in
                appState.hadithDefaultBookID = (newValue == "featured") ? nil : newValue
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(appState.localized("settings_selected_city"), systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(appState.selectedCity)
                                .fontWeight(.semibold)
                        }

                        Button(appState.localized("settings_change_city")) {
                            isCityPickerPresented = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            settingRow(title: appState.localized("settings_notifications"), symbol: "bell.badge")
                        }

                        NavigationLink {
                            AppIconSettingsView()
                        } label: {
                            settingRow(title: appState.localized("settings_app_icon"), symbol: "app.badge")
                        }

                        NavigationLink {
                            QiblaCompassView()
                        } label: {
                            settingRow(title: appState.localized("settings_qibla_compass"), symbol: "location.north")
                        }

                        NavigationLink {
                            QiblaMapView()
                        } label: {
                            settingRow(title: appState.localized("settings_qibla_map"), symbol: "map")
                        }

                        NavigationLink {
                            QuranReadingSettingsView()
                        } label: {
                            settingRow(title: appState.localized("settings_quran_reading"), symbol: "book.pages")
                        }

                        NavigationLink {
                            AboutView()
                        } label: {
                            settingRow(title: appState.localized("settings_about"), symbol: "info.circle")
                        }
                    }
                    .premiumCardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(appState.localized("settings_theme_and_data"))
                            .font(.headline)

                        Picker(appState.localized("settings_premium_theme_pack"), selection: $appState.premiumThemePack) {
                            ForEach(PremiumThemePack.allCases) { pack in
                                Text(pack.rawValue).tag(pack)
                            }
                        }

                        Picker(appState.localized("settings_language"), selection: $appState.language) {
                            ForEach(AppLanguage.allCases) { option in
                                Text(option.displayTitle).tag(option)
                            }
                        }

                        Picker(appState.localized("settings_theme"), selection: $appState.theme) {
                            ForEach(ThemeOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker(appState.localized("settings_accent"), selection: $appState.accent) {
                            ForEach(AccentOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        Picker(appState.localized("settings_data_source"), selection: $appState.dataSource) {
                            ForEach(DataSourceOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(appState.localized("tab_hadith"))
                            .font(.headline)

                        Toggle(appState.localized("settings_daily_hadith_toggle"), isOn: $appState.hadithDailyEnabled)

                        if appState.hadithDailyEnabled {
                            DatePicker(appState.localized("settings_time"), selection: $appState.hadithDailyTime, displayedComponents: .hourAndMinute)
                        }

                        Toggle(appState.localized("settings_hadith_before_prayer"), isOn: $appState.hadithNearPrayerEnabled)

                        HStack {
                            Text(appState.localized("settings_hadith_source"))
                            Spacer()
                            Text(appState.hadithSource.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Picker(appState.localized("settings_default_collection"), selection: defaultHadithBookBinding) {
                            Text(appState.localized("settings_featured_collection")).tag("featured")
                            ForEach(appState.hadithBooks) { book in
                                Text(book.title).tag(book.id)
                            }
                        }

                        Picker(appState.localized("settings_text_size"), selection: $appState.hadithTextSize) {
                            ForEach(HadithTextSize.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle(appState.localized("settings_simple_reading_mode"), isOn: $appState.hadithReadingModeSimple)

                        HStack(spacing: 10) {
                            Button(appState.localized("settings_sync_hadith")) {
                                Task {
                                    await appState.syncHadithCatalog()
                                }
                            }
                            .buttonStyle(.bordered)

                            Text(hadithSyncStatusTitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Premium ve Reklam")
                            .font(.headline)

                        if adManager.isAdFreeActive, let adFreeUntil = adManager.adFreeUntil {
                            Label(
                                "Reklamsiz mod aktif: \(adFreeUntil.formatted(.dateTime.day().month().hour().minute()))",
                                systemImage: "sparkles"
                            )
                            .foregroundStyle(.green)
                            .font(.subheadline)
                        } else {
                            Text("Reklam izleyerek 24 saat reklamsiz deneyimi acabilirsiniz.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button {
                                adManager.showRewardedUnlock()
                            } label: {
                                Label("Reklamsiz 24 Saat Ac (Rewarded)", systemImage: "play.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(PremiumPalette.navy)
                            .disabled(!adManager.isSDKReady)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        Text(appState.localized("settings_permission_status"))
                            .font(.headline)

                        HStack {
                            Text(appState.localized("settings_location"))
                            Spacer()
                            Text(locationManager.statusDescription)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text(appState.localized("settings_notifications"))
                            Spacer()
                            Text(notificationManager.statusTitle)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()
                }
                .padding()
            }
            .navigationTitle(appState.localized("screen_settings"))
            .premiumScreenBackground()
        }
        .sheet(isPresented: $isCityPickerPresented) {
            CityPickerSheet()
                .environmentObject(appState)
        }
    }

    @ViewBuilder
    private func settingRow(title: String, symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 8)
    }

    private var hadithSyncStatusTitle: String {
        switch appState.hadithSyncState {
        case .idle:
            return appState.localized("settings_sync_idle")
        case .syncing:
            return appState.localized("settings_syncing")
        case .synced(let count, let date):
            let dateString = date.formatted(.dateTime.hour().minute())
            return appState.localized("settings_synced_count", count, dateString)
        case .failed(let message):
            return appState.localized("settings_sync_failed", message)
        }
    }
}
