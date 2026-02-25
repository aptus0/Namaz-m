import Foundation

enum PrayerName: String, CaseIterable, Identifiable, Codable {
    case imsak
    case gunes
    case ogle
    case ikindi
    case aksam
    case yatsi

    var id: Self { self }

    var title: String {
        switch self {
        case .imsak:
            return "Imsak"
        case .gunes:
            return "Gunes"
        case .ogle:
            return "Ogle"
        case .ikindi:
            return "Ikindi"
        case .aksam:
            return "Aksam"
        case .yatsi:
            return "Yatsi"
        }
    }

    var symbolName: String {
        switch self {
        case .imsak:
            return "moon.stars"
        case .gunes:
            return "sunrise"
        case .ogle:
            return "sun.max"
        case .ikindi:
            return "sun.haze"
        case .aksam:
            return "sunset"
        case .yatsi:
            return "moon"
        }
    }

    var orderIndex: Int {
        switch self {
        case .imsak:
            return 0
        case .gunes:
            return 1
        case .ogle:
            return 2
        case .ikindi:
            return 3
        case .aksam:
            return 4
        case .yatsi:
            return 5
        }
    }
}

struct PrayerReminderSetting: Identifiable, Equatable {
    var prayer: PrayerName
    var isEnabled: Bool
    var leadTime: ReminderLeadTime
    var mode: ReminderMode
    var tone: AlarmTone

    var id: PrayerName { prayer }

    static var defaults: [PrayerReminderSetting] {
        PrayerName.allCases.map { prayer in
            PrayerReminderSetting(
                prayer: prayer,
                isEnabled: prayer != .gunes,
                leadTime: .tenMinutes,
                mode: .notification,
                tone: .default
            )
        }
    }
}

struct PrayerDefinition: Equatable {
    let prayer: PrayerName
    let hour: Int
    let minute: Int
}

struct PrayerEntry: Identifiable, Equatable {
    let prayer: PrayerName
    let date: Date

    var id: String {
        "\(prayer.rawValue)-\(Int(date.timeIntervalSince1970))"
    }
}

struct PrayerTimeline: Equatable {
    let previous: PrayerEntry
    let next: PrayerEntry
}

struct AlarmEvent: Identifiable, Equatable {
    let id: String
    let prayer: PrayerName
    let fireDate: Date
}

enum PrayerScheduleProvider {
    private static let baseDefinitions: [PrayerDefinition] = [
        PrayerDefinition(prayer: .imsak, hour: 5, minute: 42),
        PrayerDefinition(prayer: .gunes, hour: 7, minute: 6),
        PrayerDefinition(prayer: .ogle, hour: 13, minute: 12),
        PrayerDefinition(prayer: .ikindi, hour: 16, minute: 30),
        PrayerDefinition(prayer: .aksam, hour: 19, minute: 7),
        PrayerDefinition(prayer: .yatsi, hour: 20, minute: 26)
    ]

    static func entries(for day: Date) -> [PrayerEntry] {
        let calendar = Calendar.current
        return baseDefinitions.compactMap { definition in
            calendar.date(bySettingHour: definition.hour, minute: definition.minute, second: 0, of: day)
                .map { PrayerEntry(prayer: definition.prayer, date: $0) }
        }
    }

    static func timeline(now: Date) -> PrayerTimeline {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let all = (entries(for: yesterday) + entries(for: now) + entries(for: tomorrow)).sorted { $0.date < $1.date }

        guard let nextIndex = all.firstIndex(where: { $0.date > now }) else {
            let todayEntries = entries(for: now)
            return PrayerTimeline(previous: todayEntries[todayEntries.count - 2], next: todayEntries[todayEntries.count - 1])
        }

        let previous = all[max(0, nextIndex - 1)]
        let next = all[nextIndex]
        return PrayerTimeline(previous: previous, next: next)
    }
}
