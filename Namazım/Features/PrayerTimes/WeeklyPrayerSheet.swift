import SwiftUI

struct WeeklyPrayerSheet: View {
    @EnvironmentObject private var appState: AppState
    let referenceDate: Date
    @Environment(\.dismiss) private var dismiss

    private var days: [Date] {
        nextNDays(from: referenceDate, count: 7)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(days, id: \.self) { day in
                    Section(day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))) {
                        ForEach(PrayerScheduleProvider.entries(for: day)) { entry in
                            HStack {
                                Text(entry.prayer.localizedTitle(language: appState.language))
                                Spacer()
                                Text(entry.date, format: .dateTime.hour().minute())
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Haftalık Vakitler")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}
