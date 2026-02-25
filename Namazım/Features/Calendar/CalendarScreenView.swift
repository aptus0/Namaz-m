import SwiftUI
import Combine

enum CalendarTab: String, CaseIterable, Identifiable {
    case monthly = "Aylik Vakitler"
    case ramadan = "Ramazan"

    var id: Self { self }
}

struct CalendarScreenView: View {
    @State private var selectedTab: CalendarTab = .monthly
    @State private var selectedDate = Date()
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ay Secimi")
                            .font(.headline)
                        DatePicker("Ay Sec", selection: $selectedDate, displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()

                    Picker("Takvim", selection: $selectedTab) {
                        ForEach(CalendarTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedTab == .monthly {
                        MonthlyPrayerList(month: selectedDate)
                    } else {
                        RamadanPrayerList(referenceDate: selectedDate, now: now)
                    }
                }
                .padding()
            }
            .navigationTitle("Takvim")
            .premiumScreenBackground()
        }
        .onReceive(timer) { now = $0 }
    }
}

private struct MonthlyPrayerList: View {
    let month: Date

    private var days: [Date] {
        monthDays(for: month)
    }

    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(days, id: \.self) { day in
                PrayerDayListRow(day: day, entries: PrayerScheduleProvider.entries(for: day))
            }
        }
    }
}

private struct PrayerDayListRow: View {
    let day: Date
    let entries: [PrayerEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                .font(.headline)

            VStack(spacing: 6) {
                ForEach(entries) { entry in
                    HStack {
                        Label(entry.prayer.title, systemImage: entry.prayer.symbolName)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.date, format: .dateTime.hour().minute())
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }
}

private struct RamadanPrayerList: View {
    let referenceDate: Date
    let now: Date

    private var dates: [Date] {
        nextNDays(from: referenceDate, count: 30)
    }

    private var nextIftar: Date {
        let todayIftar = PrayerScheduleProvider.entries(for: now).first(where: { $0.prayer == .aksam })?.date ?? now
        if todayIftar > now {
            return todayIftar
        }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return PrayerScheduleProvider.entries(for: tomorrow).first(where: { $0.prayer == .aksam })?.date ?? now
    }

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bugun")
                    .font(.headline)
                Text("Iftara kalan sure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(countdownString(from: now, to: nextIftar))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .premiumCardStyle()

            LazyVStack(spacing: 8) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, day in
                    let entries = PrayerScheduleProvider.entries(for: day)
                    let imsak = entries.first(where: { $0.prayer == .imsak })?.date ?? day
                    let iftar = entries.first(where: { $0.prayer == .aksam })?.date ?? day

                    HStack {
                        Text("\(index + 1). Gun")
                            .font(.headline)
                        Spacer()
                        Text("Imsak \(imsak, format: .dateTime.hour().minute())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Iftar \(iftar, format: .dateTime.hour().minute())")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .premiumCardStyle()
                }
            }
        }
    }
}
