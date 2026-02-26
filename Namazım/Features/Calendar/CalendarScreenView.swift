import SwiftUI
import Combine

enum CalendarTab: String, CaseIterable, Identifiable {
    case monthly
    case ramadan

    var id: Self { self }
}

struct CalendarScreenView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var adManager: AdManager

    @State private var selectedTab: CalendarTab = .monthly
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var currentCity: WorldCity? {
        let selected = normalize(appState.selectedCity)
        return WorldCityCatalog.all.first { normalize($0.name) == selected }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    monthHeader

                    Picker(appState.localized("tab_calendar"), selection: $selectedTab) {
                        Text(appState.localized("calendar_month")).tag(CalendarTab.monthly)
                        Text(appState.localized("calendar_ramadan")).tag(CalendarTab.ramadan)
                    }
                    .pickerStyle(.segmented)

                    if selectedTab == .monthly {
                        MonthGridCalendarView(
                            displayedMonth: $displayedMonth,
                            selectedDate: $selectedDate
                        )

                        SelectedDayPrayerCard(
                            selectedDate: selectedDate,
                            selectedCity: appState.selectedCity,
                            city: currentCity,
                            language: appState.language
                        )
                    } else {
                        RamadanPrayerList(referenceDate: displayedMonth, now: now, city: currentCity)
                    }

                    if adManager.shouldShowBannerAds {
                        BannerAdView(adUnitID: AdMobConfig.bannerUnitID)
                            .frame(height: 60)
                            .premiumCardStyle()
                    }
                }
                .padding()
            }
            .navigationTitle(appState.localized("tab_calendar"))
            .premiumScreenBackground()
        }
        .onReceive(timer) { now = $0 }
    }

    private var monthHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    displayedMonth = shiftMonth(displayedMonth, by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)

                Spacer()

                Text(monthTitle(displayedMonth))
                    .font(.headline)

                Spacer()

                Button {
                    displayedMonth = shiftMonth(displayedMonth, by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
            }

            DatePicker(
                appState.localized("calendar_month"),
                selection: $displayedMonth,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
        }
        .premiumCardStyle()
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appState.language.locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return formatter.string(from: date)
    }

    private func shiftMonth(_ date: Date, by amount: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: amount, to: date) ?? date
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }
}

private struct MonthGridCalendarView: View {
    @EnvironmentObject private var appState: AppState

    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = appState.language.locale
        return calendar
    }

    private var monthDays: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else {
            return []
        }

        let firstWeekdayIndex = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let leading: [Date?] = Array(repeating: nil, count: firstWeekdayIndex)

        let days: [Date?] = monthRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }

        return leading + days
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = appState.language.locale
        let symbols = formatter.veryShortStandaloneWeekdaySymbols
            ?? formatter.shortWeekdaySymbols
            ?? ["S", "M", "T", "W", "T", "F", "S"]

        let first = calendar.firstWeekday - 1
        let prefix = Array(symbols[first...])
        let suffix = Array(symbols[..<first])
        return prefix + suffix
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        MonthDayCell(
                            date: day,
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDate)
                        )
                        .onTapGesture {
                            selectedDate = day
                        }
                    } else {
                        Color.clear
                            .frame(height: 52)
                    }
                }
            }
        }
        .premiumCardStyle()
    }
}

private struct MonthDayCell: View {
    @EnvironmentObject private var appState: AppState

    let date: Date
    let isSelected: Bool

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var hijriDay: Int {
        HijriCalendarService.dayNumber(for: date)
    }

    private var hasSpecialDay: Bool {
        HijriCalendarService.specialDayKey(for: date) != nil
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(date, format: .dateTime.day())
                .font(.subheadline.weight(isToday || isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)

            Text("\(hijriDay)")
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)

            Circle()
                .fill(hasSpecialDay ? PremiumPalette.gold : .clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? PremiumPalette.navy : (isToday ? PremiumPalette.navy.opacity(0.12) : Color.clear))
        )
    }
}

private struct SelectedDayPrayerCard: View {
    @EnvironmentObject private var appState: AppState

    let selectedDate: Date
    let selectedCity: String
    let city: WorldCity?
    let language: AppLanguage

    private var entries: [PrayerEntry] {
        if let city {
            return SolarPrayerTimeService.entries(for: city, day: selectedDate)
        }
        return PrayerScheduleProvider.entries(for: selectedDate)
    }

    private var specialDayText: String? {
        guard let key = HijriCalendarService.specialDayKey(for: selectedDate) else { return nil }
        return appState.localized(key)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(appState.localized("calendar_selected_day"))
                    .font(.headline)
                Spacer()
                Text(selectedCity)
                    .font(.subheadline.weight(.semibold))
            }

            Text("\(appState.localized("calendar_gregorian")): \(selectedDate.formatted(.dateTime.weekday(.wide).day().month().year()))")
                .font(.subheadline)

            Text("\(appState.localized("calendar_hijri")): \(HijriCalendarService.fullHijriDateString(for: selectedDate, locale: language.locale))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let specialDayText {
                Text("\(appState.localized("calendar_special_day")): \(specialDayText)")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(PremiumPalette.gold.opacity(0.2)))
            }

            Divider()

            ForEach(entries) { entry in
                HStack {
                    Text(entry.prayer.localizedTitle(language: language))
                    Spacer()
                    Text(entry.date, format: .dateTime.hour().minute())
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
        }
        .premiumCardStyle()
    }
}

private struct RamadanPrayerList: View {
    @EnvironmentObject private var appState: AppState

    let referenceDate: Date
    let now: Date
    let city: WorldCity?

    private var dates: [Date] {
        nextNDays(from: referenceDate, count: 30)
    }

    private var nextIftar: Date {
        let entries = city.map { SolarPrayerTimeService.entries(for: $0, day: now) } ?? PrayerScheduleProvider.entries(for: now)
        let todayIftar = entries.first(where: { $0.prayer == .aksam })?.date ?? now

        if todayIftar > now {
            return todayIftar
        }

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowEntries = city.map { SolarPrayerTimeService.entries(for: $0, day: tomorrow) } ?? PrayerScheduleProvider.entries(for: tomorrow)
        return tomorrowEntries.first(where: { $0.prayer == .aksam })?.date ?? now
    }

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(appState.localized("calendar_ramadan"))
                    .font(.headline)
                Text(appState.localized("world_remaining"))
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
                    let entries = city.map { SolarPrayerTimeService.entries(for: $0, day: day) } ?? PrayerScheduleProvider.entries(for: day)
                    let imsak = entries.first(where: { $0.prayer == .imsak })?.date ?? day
                    let iftar = entries.first(where: { $0.prayer == .aksam })?.date ?? day

                    HStack {
                        Text("\(index + 1). \(appState.localized("calendar_ramadan"))")
                            .font(.headline)
                        Spacer()
                        Text("\(appState.localized("prayer_name_imsak")) \(imsak, format: .dateTime.hour().minute())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(appState.localized("prayer_name_aksam")) \(iftar, format: .dateTime.hour().minute())")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .premiumCardStyle()
                }
            }
        }
    }
}
