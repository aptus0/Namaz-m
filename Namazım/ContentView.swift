//
//  ContentView.swift
//  Namazım
//
//  Created by Samet on 25.02.2026.
//

import SwiftUI
import UIKit

final class AppState: ObservableObject {
    @Published var selectedCity: String = "Kocaeli"
    @Published var theme: ThemeOption = .system
    @Published var accent: AccentOption = .teal
    @Published var dataSource: DataSourceOption = .diyanet
    @Published var notificationOffset: NotificationOffsetOption = .onTime
    @Published var prayerNotifications: [PrayerNotificationSetting] = [
        PrayerNotificationSetting(name: "Imsak", isEnabled: true),
        PrayerNotificationSetting(name: "Gunes", isEnabled: false),
        PrayerNotificationSetting(name: "Ogle", isEnabled: true),
        PrayerNotificationSetting(name: "Ikindi", isEnabled: true),
        PrayerNotificationSetting(name: "Aksam", isEnabled: true),
        PrayerNotificationSetting(name: "Yatsi", isEnabled: true)
    ]
    @Published private(set) var favoriteContentIDs: Set<String> = []

    let cities = TurkishCities.all

    func isFavorite(_ content: DailyContent) -> Bool {
        favoriteContentIDs.contains(content.id)
    }

    func toggleFavorite(_ content: DailyContent) {
        if favoriteContentIDs.contains(content.id) {
            favoriteContentIDs.remove(content.id)
        } else {
            favoriteContentIDs.insert(content.id)
        }
    }
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case system = "Sistem"
    case light = "Acik"
    case dark = "Koyu"

    var id: Self { self }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AccentOption: String, CaseIterable, Identifiable {
    case teal = "Yesil Mavi"
    case orange = "Turuncu"
    case blue = "Mavi"

    var id: Self { self }

    var color: Color {
        switch self {
        case .teal:
            return .teal
        case .orange:
            return .orange
        case .blue:
            return .blue
        }
    }
}

enum DataSourceOption: String, CaseIterable, Identifiable {
    case diyanet = "Diyanet"
    case alternative = "Alternatif"

    var id: Self { self }
}

enum NotificationOffsetOption: String, CaseIterable, Identifiable {
    case onTime = "Tam vaktinde"
    case fiveMinutes = "5 dk once"
    case tenMinutes = "10 dk once"

    var id: Self { self }
}

struct PrayerNotificationSetting: Identifiable {
    let id = UUID()
    let name: String
    var isEnabled: Bool
}

enum DailyContentType: String {
    case hadis = "Hadis"
    case ayet = "Ayet"
    case dua = "Dua"
}

struct DailyContent: Identifiable {
    let id: String
    let title: String
    let text: String
    let source: String
    let type: DailyContentType

    var shareText: String {
        "\(title)\n\n\(text)\n\nKaynak: \(source)"
    }
}

struct PrayerDefinition {
    let name: String
    let hour: Int
    let minute: Int
}

struct PrayerEntry: Identifiable {
    let name: String
    let date: Date

    var id: String {
        "\(name)-\(date.timeIntervalSince1970)"
    }
}

enum PrayerSchedule {
    private static let definitions: [PrayerDefinition] = [
        PrayerDefinition(name: "Imsak", hour: 5, minute: 42),
        PrayerDefinition(name: "Gunes", hour: 7, minute: 6),
        PrayerDefinition(name: "Ogle", hour: 13, minute: 12),
        PrayerDefinition(name: "Ikindi", hour: 16, minute: 30),
        PrayerDefinition(name: "Aksam", hour: 19, minute: 7),
        PrayerDefinition(name: "Yatsi", hour: 20, minute: 26)
    ]

    static func entries(for day: Date) -> [PrayerEntry] {
        let calendar = Calendar.current
        return definitions.compactMap { definition in
            calendar.date(
                bySettingHour: definition.hour,
                minute: definition.minute,
                second: 0,
                of: day
            ).map { date in
                PrayerEntry(name: definition.name, date: date)
            }
        }
    }

    static func timeline(now: Date) -> (previous: PrayerEntry, next: PrayerEntry) {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let combined = (entries(for: yesterday) + entries(for: now) + entries(for: tomorrow))
            .sorted { $0.date < $1.date }

        guard let nextIndex = combined.firstIndex(where: { $0.date > now }) else {
            let fallback = entries(for: now)
            return (fallback[fallback.count - 2], fallback[fallback.count - 1])
        }

        let previousIndex = max(0, nextIndex - 1)
        return (combined[previousIndex], combined[nextIndex])
    }
}

enum CalendarTab: String, CaseIterable, Identifiable {
    case monthly = "Aylik Vakitler"
    case ramadan = "Ramazan"

    var id: Self { self }
}

enum DailyContentTab: String, CaseIterable, Identifiable {
    case yesterday = "Dun"
    case today = "Bugun"
    case tomorrow = "Yarin"

    var id: Self { self }
}

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        TabView {
            PrayerTimesView()
                .tabItem {
                    Label("Vakitler", systemImage: "clock.fill")
                }

            CalendarView()
                .tabItem {
                    Label("Takvim", systemImage: "calendar")
                }

            DailyContentView()
                .tabItem {
                    Label("Icerik", systemImage: "book.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(appState)
        .tint(appState.accent.color)
        .preferredColorScheme(appState.theme.colorScheme)
    }
}

#Preview {
    ContentView()
}

struct PrayerTimesView: View {
    @EnvironmentObject private var appState: AppState

    @State private var now = Date()
    @State private var isCityPickerPresented = false
    @State private var isWeeklyViewPresented = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var todayEntries: [PrayerEntry] {
        PrayerSchedule.entries(for: now)
    }

    private var timeline: (previous: PrayerEntry, next: PrayerEntry) {
        PrayerSchedule.timeline(now: now)
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
                        prayerName: timeline.next.name,
                        countdownText: countdownString(from: now, to: timeline.next.date),
                        progress: progress
                    )

                    VStack(spacing: 10) {
                        ForEach(todayEntries) { entry in
                            PrayerTimeCard(
                                entry: entry,
                                isActive: entry.name == timeline.next.name
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

                        Button {
                            // Ayarlar sekmesine gecis sonraki adimda state ile baglanabilir.
                        } label: {
                            Label("Bildirimler", systemImage: "bell")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
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

struct CalendarView: View {
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
                        DatePicker(
                            "Ay Sec",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    Picker("Takvim", selection: $selectedTab) {
                        ForEach(CalendarTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedTab == .monthly {
                        MonthlyPrayerList(month: selectedDate)
                    } else {
                        RamadanList(referenceDate: selectedDate, now: now)
                    }
                }
                .padding()
            }
            .navigationTitle("Takvim")
        }
        .onReceive(timer) { now = $0 }
    }
}

struct DailyContentView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selectedTab: DailyContentTab = .today
    @State private var isCopyAlertPresented = false

    private let contentsByTab: [DailyContentTab: DailyContent] = [
        .yesterday: DailyContent(
            id: "content-yesterday",
            title: "Gunun Duasi",
            text: "Allahim kalbimize huzur, evlerimize bereket, omrumuze hayir nasip eyle.",
            source: "Dua Mecmuasi",
            type: .dua
        ),
        .today: DailyContent(
            id: "content-today",
            title: "Gunun Hadisi",
            text: "Kolaylastiriniz, zorlastirmayiniz; mujdeleyiniz, nefret ettirmeyiniz.",
            source: "Buhari, Ilim",
            type: .hadis
        ),
        .tomorrow: DailyContent(
            id: "content-tomorrow",
            title: "Gunun Ayeti",
            text: "Suphesiz Allah sabredenlerle beraberdir.",
            source: "Bakara 2:153",
            type: .ayet
        )
    ]

    private var selectedContent: DailyContent {
        contentsByTab[selectedTab] ?? contentsByTab[.today]!
    }

    private var allContents: [DailyContent] {
        DailyContentTab.allCases.compactMap { contentsByTab[$0] }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("Gun", selection: $selectedTab) {
                        ForEach(DailyContentTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(selectedContent.title)
                                .font(.title3.weight(.semibold))
                            Spacer()
                            ContentTypeBadge(type: selectedContent.type)
                        }

                        Text(selectedContent.text)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Kaynak: \(selectedContent.source)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    VStack(spacing: 10) {
                        ShareLink(item: selectedContent.shareText) {
                            Label("Paylas", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            UIPasteboard.general.string = selectedContent.shareText
                            isCopyAlertPresented = true
                        } label: {
                            Label("Kopyala", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            appState.toggleFavorite(selectedContent)
                        } label: {
                            Label(
                                appState.isFavorite(selectedContent) ? "Favoriden Cikar" : "Favoriye Ekle",
                                systemImage: appState.isFavorite(selectedContent) ? "heart.slash" : "heart"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    NavigationLink {
                        FavoritesView(allContents: allContents)
                    } label: {
                        Label("Favorileri Gor", systemImage: "bookmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Gunun Icerigi")
            .alert("Icerik panoya kopyalandi.", isPresented: $isCopyAlertPresented) {
                Button("Tamam", role: .cancel) {}
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
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

                Section("Bildirimler") {
                    Picker("Bildirim Zamani", selection: $appState.notificationOffset) {
                        ForEach(NotificationOffsetOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    ForEach($appState.prayerNotifications) { $prayer in
                        Toggle(prayer.name, isOn: $prayer.isEnabled)
                    }
                }

                Section("Tema") {
                    Picker("Gorunum", selection: $appState.theme) {
                        ForEach(ThemeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Aksan Rengi", selection: $appState.accent) {
                        ForEach(AccentOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section("Veri Kaynagi") {
                    Picker("Kaynak", selection: $appState.dataSource) {
                        ForEach(DataSourceOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
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

struct NextPrayerCard: View {
    let prayerName: String
    let countdownText: String
    let progress: Double

    var body: some View {
        VStack(spacing: 14) {
            Text("Bir Sonraki Vakit")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text("\(prayerName)'a")
                        .font(.headline)
                    Text(countdownText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 220, height: 220)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct PrayerTimeCard: View {
    let entry: PrayerEntry
    let isActive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline)
                if isActive {
                    Text("Siradaki vakit")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()

            Text(entry.date, format: .dateTime.hour().minute())
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1.5)
        }
    }
}

struct MonthlyPrayerList: View {
    let month: Date

    private var days: [Date] {
        monthDays(for: month)
    }

    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(days, id: \.self) { day in
                PrayerDayGridCard(day: day, entries: PrayerSchedule.entries(for: day))
            }
        }
    }
}

struct PrayerDayGridCard: View {
    let day: Date
    let entries: [PrayerEntry]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(entries) { entry in
                    VStack(spacing: 4) {
                        Text(entry.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(entry.date, format: .dateTime.hour().minute())
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct RamadanList: View {
    let referenceDate: Date
    let now: Date

    private var dates: [Date] {
        let start = Calendar.current.startOfDay(for: referenceDate)
        return (0..<30).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: start)
        }
    }

    private var nextIftar: Date {
        let todayIftar = PrayerSchedule.entries(for: now).first(where: { $0.name == "Aksam" })?.date ?? now
        if todayIftar > now {
            return todayIftar
        }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return PrayerSchedule.entries(for: tomorrow).first(where: { $0.name == "Aksam" })?.date ?? now
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )

            LazyVStack(spacing: 8) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, day in
                    let entries = PrayerSchedule.entries(for: day)
                    let imsak = entries.first(where: { $0.name == "Imsak" })?.date ?? day
                    let iftar = entries.first(where: { $0.name == "Aksam" })?.date ?? day

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
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
    }
}

struct WeeklyPrayerSheet: View {
    let referenceDate: Date
    @Environment(\.dismiss) private var dismiss

    private var days: [Date] {
        let start = Calendar.current.startOfDay(for: referenceDate)
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: start)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(days, id: \.self) { day in
                    Section(day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))) {
                        ForEach(PrayerSchedule.entries(for: day)) { entry in
                            HStack {
                                Text(entry.name)
                                Spacer()
                                Text(entry.date, format: .dateTime.hour().minute())
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Haftalik Vakitler")
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

struct CityPickerSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var filteredCities: [String] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return appState.cities
        }
        return appState.cities.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredCities, id: \.self) { city in
                Button {
                    appState.selectedCity = city
                    dismiss()
                } label: {
                    HStack {
                        Text(city)
                            .foregroundStyle(.primary)
                        Spacer()
                        if city == appState.selectedCity {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Sehir ara")
            .navigationTitle("Il Sec")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState
    let allContents: [DailyContent]

    private var favorites: [DailyContent] {
        allContents.filter { appState.isFavorite($0) }
    }

    var body: some View {
        List {
            if favorites.isEmpty {
                Text("Henuz favori icerik yok.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(favorites) { content in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(content.title)
                                .font(.headline)
                            Spacer()
                            ContentTypeBadge(type: content.type)
                        }
                        Text(content.text)
                            .lineLimit(3)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Favoriler")
    }
}

struct AboutView: View {
    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.1"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section("Uygulama") {
                LabeledContent("Surum", value: appVersionText)
                LabeledContent("Veri Kaynagi", value: "Diyanet / Alternatif")
            }

            Section("Gizlilik") {
                Text("Gizlilik metni ve kaynaklar sonraki surumde detaylandirilacak.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Hakkinda")
    }
}

struct ContentTypeBadge: View {
    let type: DailyContentType

    var body: some View {
        Text(type.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
            )
    }
}

enum TurkishCities {
    static let all: [String] = [
        "Adana", "Adiyaman", "Afyonkarahisar", "Agri", "Amasya", "Ankara", "Antalya", "Artvin",
        "Aydin", "Balikesir", "Bilecik", "Bingol", "Bitlis", "Bolu", "Burdur", "Bursa", "Canakkale",
        "Cankiri", "Corum", "Denizli", "Diyarbakir", "Edirne", "Elazig", "Erzincan", "Erzurum",
        "Eskisehir", "Gaziantep", "Giresun", "Gumushane", "Hakkari", "Hatay", "Isparta", "Mersin",
        "Istanbul", "Izmir", "Kars", "Kastamonu", "Kayseri", "Kirklareli", "Kirsehir", "Kocaeli",
        "Konya", "Kutahya", "Malatya", "Manisa", "Kahramanmaras", "Mardin", "Mugla", "Mus",
        "Nevsehir", "Nigde", "Ordu", "Rize", "Sakarya", "Samsun", "Siirt", "Sinop", "Sivas",
        "Tekirdag", "Tokat", "Trabzon", "Tunceli", "Sanliurfa", "Usak", "Van", "Yozgat", "Zonguldak",
        "Aksaray", "Bayburt", "Karaman", "Kirikkale", "Batman", "Sirnak", "Bartin", "Ardahan",
        "Igdir", "Yalova", "Karabuk", "Kilis", "Osmaniye", "Duzce"
    ]
}

private func countdownString(from start: Date, to end: Date) -> String {
    let totalSeconds = max(0, Int(end.timeIntervalSince(start)))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

private func monthDays(for month: Date) -> [Date] {
    guard let interval = Calendar.current.dateInterval(of: .month, for: month) else {
        return []
    }

    var days: [Date] = []
    var cursor = interval.start

    while cursor < interval.end {
        days.append(cursor)
        cursor = Calendar.current.date(byAdding: .day, value: 1, to: cursor) ?? interval.end
    }

    return days
}
