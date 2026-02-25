import SwiftUI
import Combine

struct PrayerTimesView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    @State private var now = Date()
    @State private var isCityPickerPresented = false
    @State private var isWeeklyViewPresented = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var todayEntries: [PrayerEntry] {
        PrayerScheduleProvider.entries(for: now)
    }

    private var timeline: PrayerTimeline {
        PrayerScheduleProvider.timeline(now: now)
    }

    private var progress: Double {
        let total = timeline.next.date.timeIntervalSince(timeline.previous.date)
        guard total > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(timeline.previous.date)
        return min(max(elapsed / total, 0), 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 10) {
                        Button {
                            isCityPickerPresented = true
                        } label: {
                            Label(appState.selectedCity, systemImage: "mappin.and.ellipse")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button {
                            now = Date()
                            locationManager.requestSingleLocation()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)
                    }

                    locationStatusCard

                    NextPrayerCard(
                        prayerName: timeline.next.prayer.title,
                        countdownText: countdownString(from: now, to: timeline.next.date),
                        progress: progress
                    )

                    VStack(spacing: 10) {
                        ForEach(todayEntries) { entry in
                            PrayerTimeRowCard(
                                entry: entry,
                                isActive: entry.prayer == timeline.next.prayer
                            )
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            isWeeklyViewPresented = true
                        } label: {
                            Label("Haftalik Gorunum", systemImage: "calendar.badge.clock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PremiumPalette.navy)

                        Label("Canli", systemImage: "dot.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }

                    Text("Son guncelleme: \(now, format: .dateTime.hour().minute().second())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Vakitler")
            .premiumScreenBackground()
        }
        .onReceive(timer) { now = $0 }
        .onAppear {
            locationManager.requestSingleLocation()
        }
        .onChange(of: locationManager.resolvedCity) { _, city in
            appState.applyDetectedCity(city)
        }
        .sheet(isPresented: $isCityPickerPresented) {
            CityPickerSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $isWeeklyViewPresented) {
            WeeklyPrayerSheet(referenceDate: now)
        }
    }

    private var locationStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Konum Durumu")
                .font(.headline)

            if locationManager.isLocating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Konum aliniyor...")
                        .font(.subheadline)
                }
            } else {
                Text(locationManager.statusDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if locationManager.isDenied {
                Button("Konum Ayarlarini Ac") {
                    locationManager.openAppSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }
}
