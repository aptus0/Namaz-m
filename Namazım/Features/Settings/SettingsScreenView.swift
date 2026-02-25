import SwiftUI

struct SettingsScreenView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var adManager: AdManager

    @State private var isCityPickerPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Secili Il", systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(appState.selectedCity)
                                .fontWeight(.semibold)
                        }

                        Button("Ili Degistir") {
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
                            settingRow(title: "Bildirim Ayarlari", symbol: "bell.badge")
                        }

                        NavigationLink {
                            QiblaCompassView()
                        } label: {
                            settingRow(title: "Kible (Pusula)", symbol: "location.north")
                        }

                        NavigationLink {
                            QiblaMapView()
                        } label: {
                            settingRow(title: "Kible (Harita)", symbol: "map")
                        }

                        NavigationLink {
                            AboutView()
                        } label: {
                            settingRow(title: "Hakkinda / Kaynaklar", symbol: "info.circle")
                        }
                    }
                    .premiumCardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tema ve Veri")
                            .font(.headline)

                        Picker("Tema", selection: $appState.theme) {
                            ForEach(ThemeOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Aksan", selection: $appState.accent) {
                            ForEach(AccentOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        Picker("Kaynak", selection: $appState.dataSource) {
                            ForEach(DataSourceOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
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
                        Text("Izin Durumlari")
                            .font(.headline)

                        HStack {
                            Text("Konum")
                            Spacer()
                            Text(locationManager.statusDescription)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("Bildirim")
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
            .navigationTitle("Ayarlar")
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
}
