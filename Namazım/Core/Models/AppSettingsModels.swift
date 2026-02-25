import SwiftUI

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
    case premiumBlue = "Premium Mavi"
    case teal = "Yesil Mavi"
    case warmGold = "Altin"

    var id: Self { self }

    var color: Color {
        switch self {
        case .premiumBlue:
            return Color(red: 0.09, green: 0.34, blue: 0.91)
        case .teal:
            return .teal
        case .warmGold:
            return Color(red: 0.88, green: 0.68, blue: 0.20)
        }
    }
}

enum DataSourceOption: String, CaseIterable, Identifiable {
    case diyanet = "Diyanet"
    case fallback = "Alternatif"

    var id: Self { self }
}

enum ReminderLeadTime: Int, CaseIterable, Identifiable {
    case onTime = 0
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30

    var id: Self { self }

    var title: String {
        switch self {
        case .onTime:
            return "Tam vaktinde"
        case .fiveMinutes:
            return "5 dk once"
        case .tenMinutes:
            return "10 dk once"
        case .fifteenMinutes:
            return "15 dk once"
        case .thirtyMinutes:
            return "30 dk once"
        }
    }
}

enum ReminderMode: String, CaseIterable, Identifiable {
    case notification = "Bildirim"
    case alarm = "Alarm"

    var id: Self { self }
}

enum AlarmTone: String, CaseIterable, Identifiable {
    case `default` = "Varsayilan"
    case ezan1 = "Ezan 1"
    case ezan2 = "Ezan 2"
    case systemTone = "Telefon Sesi"

    var id: Self { self }

    var fileName: String? {
        switch self {
        case .default:
            return nil
        case .ezan1:
            return "ezan1.wav"
        case .ezan2:
            return "ezan2.wav"
        case .systemTone:
            return nil
        }
    }
}
