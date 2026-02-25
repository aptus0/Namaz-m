import SwiftUI
import Combine

struct PrayerTimesView: View {
    @EnvironmentObject private var appState: AppState

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
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)
                    }

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

                        Label("Canli", systemImage: "dot.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
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
        }
        .onReceive(timer) { now = $0 }
        .sheet(isPresented: $isCityPickerPresented) {
            CityPickerSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $isWeeklyViewPresented) {
            WeeklyPrayerSheet(referenceDate: now)
        }
    }
}
