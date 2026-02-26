import SwiftUI
import Combine

struct PrayerTimesView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    @State private var now = Date()
    @State private var isCityPickerPresented = false
    @State private var isWeeklyViewPresented = false

    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    private var activeCity: WorldCity? {
        let selected = normalize(appState.selectedCity)
        return WorldCityCatalog.all.first { normalize($0.name) == selected }
    }

    private var todayEntries: [PrayerEntry] {
        if let activeCity {
            return SolarPrayerTimeService.entries(for: activeCity, day: now)
        }
        return PrayerScheduleProvider.entries(for: now)
    }

    private var timeline: PrayerTimeline {
        if let activeCity {
            return SolarPrayerTimeService.timeline(for: activeCity, now: now)
        }
        return PrayerScheduleProvider.timeline(now: now)
    }

    private var currentTimeText: String {
        now.formatted(.dateTime.hour().minute().second())
    }

    private var nextPrayerTitle: String {
        timeline.next.prayer.localizedTitle(language: appState.language)
    }

    private var nextPrayerTimeText: String {
        timeline.next.date.formatted(.dateTime.hour().minute())
    }

    private var remainingText: String {
        countdownString(from: now, to: timeline.next.date)
    }

    private var hijriDateText: String {
        HijriCalendarService.fullHijriDateString(for: now, locale: appState.language.locale)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroHeaderCard

                    NextPrayerCard(
                        prayerName: nextPrayerTitle,
                        nextDate: timeline.next.date,
                        previousDate: timeline.previous.date
                    )

                    prayerListCard

                    locationStatusCard

                    HStack(spacing: 12) {
                        Button {
                            isWeeklyViewPresented = true
                        } label: {
                            Label(appState.localized("prayer_weekly"), systemImage: "calendar.badge.clock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PremiumPalette.navy)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text(appState.localized("prayer_live"))
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.66))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(PremiumPalette.navy.opacity(0.14), lineWidth: 1)
                        )
                    }

                    Text("\(appState.localized("prayer_last_update")): \(currentTimeText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(appState.localized("tab_prayers"))
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

    private var heroHeaderCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            PremiumPalette.navy.opacity(0.96),
                            Color(red: 0.12, green: 0.28, blue: 0.56),
                            PremiumPalette.sky.opacity(0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(PremiumPalette.gold.opacity(0.28))
                .frame(width: 180, height: 180)
                .offset(x: 180, y: -80)
                .blur(radius: 16)

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 110, height: 110)
                .offset(x: -46, y: 120)
                .blur(radius: 12)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        isCityPickerPresented = true
                    } label: {
                        Label(appState.selectedCity, systemImage: "mappin.and.ellipse")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.white.opacity(0.20))

                    Spacer()

                    Button {
                        now = Date()
                        locationManager.requestSingleLocation()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.localized("prayer_next").uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))

                    Text(nextPrayerTitle)
                        .font(.system(size: 33, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label(nextPrayerTimeText, systemImage: "clock.fill")
                        Text("•")
                        Text(remainingText)
                            .monospacedDigit()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PremiumPalette.gold)
                }

                HStack {
                    Text(now.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.90))
                    Spacer()
                    Text(currentTimeText)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                Text("Hicri: \(hijriDateText)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
            }
            .padding(18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: PremiumPalette.navy.opacity(0.30), radius: 16, x: 0, y: 9)
    }

    private var prayerListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bugunun Vakitleri")
                    .font(.headline)
                Spacer()
                Text("\(todayEntries.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(PremiumPalette.gold.opacity(0.22)))
            }

            VStack(spacing: 10) {
                ForEach(todayEntries) { entry in
                    PrayerTimeRowCard(
                        entry: entry,
                        isActive: entry.prayer == timeline.next.prayer
                    )
                }
            }
        }
        .premiumCardStyle()
    }

    private var locationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(appState.localized("prayer_location_status"), systemImage: "location.fill")
                    .font(.headline)
                Spacer()
                Text(activeCity?.timeZoneID ?? "Local")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if locationManager.isLocating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(appState.localized("location_loading"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(locationManager.statusDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if locationManager.isDenied {
                Button("Konum Ayarlarını Aç") {
                    locationManager.openAppSettings()
                }
                .buttonStyle(.bordered)
                .tint(PremiumPalette.navy)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }
}
