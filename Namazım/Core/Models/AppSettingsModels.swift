import SwiftUI

enum ThemeOption: String, CaseIterable, Identifiable {
    case system = "Sistem"
    case light = "Açık"
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

enum PremiumThemePack: String, CaseIterable, Identifiable {
    case classicNavy = "Klasik Lacivert"
    case minimalWhite = "Minimal Beyaz"
    case nightBlack = "Gece Siyah"
    case ramadanGold = "Ramazan Altın"
    case natureGreen = "Emerald Green"

    var id: Self { self }
}

struct PremiumThemePalette {
    let primary: Color
    let accent: Color
    let goldAccent: Color
    let surfaceTop: Color
    let surfaceBottom: Color
    let cardTop: Color
    let cardBottom: Color
    let stroke: Color
    let textPrimary: Color
    let textSecondary: Color
    let glow: Color
}

extension PremiumThemePack {
    func palette(for colorScheme: ColorScheme) -> PremiumThemePalette {
        switch self {
        case .classicNavy:
            return PremiumThemePalette(
                primary: Color(red: 0.08, green: 0.19, blue: 0.43),
                accent: Color(red: 0.31, green: 0.56, blue: 0.95),
                goldAccent: Color(red: 0.89, green: 0.72, blue: 0.30),
                surfaceTop: colorScheme == .dark ? Color(red: 0.05, green: 0.08, blue: 0.14) : Color(red: 0.95, green: 0.97, blue: 1.0),
                surfaceBottom: colorScheme == .dark ? Color(red: 0.08, green: 0.12, blue: 0.22) : Color(red: 0.90, green: 0.94, blue: 0.99),
                cardTop: colorScheme == .dark ? Color(red: 0.12, green: 0.15, blue: 0.25) : Color.white.opacity(0.95),
                cardBottom: colorScheme == .dark ? Color(red: 0.11, green: 0.14, blue: 0.22) : Color(red: 0.89, green: 0.93, blue: 0.99),
                stroke: colorScheme == .dark ? Color.white.opacity(0.20) : Color(red: 0.11, green: 0.25, blue: 0.48).opacity(0.12),
                textPrimary: colorScheme == .dark ? Color.white : Color(red: 0.12, green: 0.17, blue: 0.27),
                textSecondary: colorScheme == .dark ? Color.white.opacity(0.72) : Color(red: 0.30, green: 0.36, blue: 0.47),
                glow: Color(red: 0.44, green: 0.62, blue: 0.95).opacity(colorScheme == .dark ? 0.30 : 0.22)
            )
        case .minimalWhite:
            return PremiumThemePalette(
                primary: Color(red: 0.16, green: 0.22, blue: 0.32),
                accent: Color(red: 0.26, green: 0.64, blue: 0.76),
                goldAccent: Color(red: 0.86, green: 0.71, blue: 0.32),
                surfaceTop: colorScheme == .dark ? Color(red: 0.12, green: 0.14, blue: 0.17) : Color(red: 0.98, green: 0.98, blue: 0.99),
                surfaceBottom: colorScheme == .dark ? Color(red: 0.09, green: 0.10, blue: 0.13) : Color(red: 0.94, green: 0.95, blue: 0.97),
                cardTop: colorScheme == .dark ? Color(red: 0.16, green: 0.17, blue: 0.22) : Color.white.opacity(0.98),
                cardBottom: colorScheme == .dark ? Color(red: 0.13, green: 0.14, blue: 0.19) : Color(red: 0.96, green: 0.97, blue: 0.99),
                stroke: colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.07),
                textPrimary: colorScheme == .dark ? Color.white : Color(red: 0.17, green: 0.20, blue: 0.28),
                textSecondary: colorScheme == .dark ? Color.white.opacity(0.70) : Color(red: 0.43, green: 0.46, blue: 0.54),
                glow: Color(red: 0.56, green: 0.79, blue: 0.86).opacity(colorScheme == .dark ? 0.18 : 0.20)
            )
        case .nightBlack:
            return PremiumThemePalette(
                primary: Color(red: 0.10, green: 0.11, blue: 0.15),
                accent: Color(red: 0.44, green: 0.55, blue: 0.86),
                goldAccent: Color(red: 0.90, green: 0.73, blue: 0.34),
                surfaceTop: Color(red: 0.04, green: 0.05, blue: 0.08),
                surfaceBottom: Color(red: 0.09, green: 0.10, blue: 0.14),
                cardTop: Color(red: 0.14, green: 0.15, blue: 0.20),
                cardBottom: Color(red: 0.10, green: 0.11, blue: 0.16),
                stroke: Color.white.opacity(0.16),
                textPrimary: Color.white,
                textSecondary: Color.white.opacity(0.72),
                glow: Color(red: 0.88, green: 0.73, blue: 0.36).opacity(0.18)
            )
        case .ramadanGold:
            return PremiumThemePalette(
                primary: Color(red: 0.22, green: 0.19, blue: 0.14),
                accent: Color(red: 0.84, green: 0.66, blue: 0.20),
                goldAccent: Color(red: 0.95, green: 0.79, blue: 0.38),
                surfaceTop: colorScheme == .dark ? Color(red: 0.10, green: 0.08, blue: 0.06) : Color(red: 0.99, green: 0.97, blue: 0.92),
                surfaceBottom: colorScheme == .dark ? Color(red: 0.14, green: 0.11, blue: 0.08) : Color(red: 0.96, green: 0.92, blue: 0.82),
                cardTop: colorScheme == .dark ? Color(red: 0.21, green: 0.17, blue: 0.12) : Color(red: 1.00, green: 0.98, blue: 0.93),
                cardBottom: colorScheme == .dark ? Color(red: 0.16, green: 0.13, blue: 0.10) : Color(red: 0.97, green: 0.93, blue: 0.86),
                stroke: colorScheme == .dark ? Color.white.opacity(0.18) : Color(red: 0.63, green: 0.47, blue: 0.16).opacity(0.24),
                textPrimary: colorScheme == .dark ? Color.white : Color(red: 0.28, green: 0.21, blue: 0.12),
                textSecondary: colorScheme == .dark ? Color.white.opacity(0.72) : Color(red: 0.46, green: 0.36, blue: 0.21),
                glow: Color(red: 0.96, green: 0.84, blue: 0.52).opacity(colorScheme == .dark ? 0.20 : 0.26)
            )
        case .natureGreen:
            return PremiumThemePalette(
                primary: Color(red: 0.07, green: 0.33, blue: 0.27),
                accent: Color(red: 0.20, green: 0.66, blue: 0.50),
                goldAccent: Color(red: 0.83, green: 0.71, blue: 0.30),
                surfaceTop: colorScheme == .dark ? Color(red: 0.04, green: 0.11, blue: 0.10) : Color(red: 0.92, green: 0.98, blue: 0.95),
                surfaceBottom: colorScheme == .dark ? Color(red: 0.07, green: 0.16, blue: 0.14) : Color(red: 0.84, green: 0.94, blue: 0.89),
                cardTop: colorScheme == .dark ? Color(red: 0.10, green: 0.20, blue: 0.18) : Color.white.opacity(0.96),
                cardBottom: colorScheme == .dark ? Color(red: 0.08, green: 0.15, blue: 0.13) : Color(red: 0.87, green: 0.95, blue: 0.91),
                stroke: colorScheme == .dark ? Color.white.opacity(0.16) : Color(red: 0.05, green: 0.30, blue: 0.22).opacity(0.16),
                textPrimary: colorScheme == .dark ? Color.white : Color(red: 0.12, green: 0.24, blue: 0.21),
                textSecondary: colorScheme == .dark ? Color.white.opacity(0.74) : Color(red: 0.25, green: 0.42, blue: 0.36),
                glow: Color(red: 0.29, green: 0.76, blue: 0.60).opacity(colorScheme == .dark ? 0.22 : 0.20)
            )
        }
    }
}

enum AccentOption: String, CaseIterable, Identifiable {
    case premiumBlue = "Lacivert"
    case teal = "Yeşil Mavi"
    case warmGold = "Altın"

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

enum AppIconChoice: String, CaseIterable, Identifiable {
    case primary = "Varsayılan"
    case crescentMinaret = "Hilal + Minare"
    case modernClock = "Saat + Hilal"
    case monogramN = "Monogram N"
    case ramadanGlow = "Ramazan Gold"
    case emeraldMark = "Emerald"

    var id: Self { self }

    var iconName: String? {
        switch self {
        case .primary:
            return nil
        case .crescentMinaret:
            return "IconCrescentMinaret"
        case .modernClock:
            return "IconModernClock"
        case .monogramN:
            return "IconMonogramN"
        case .ramadanGlow:
            return "IconRamadanGold"
        case .emeraldMark:
            return "IconEmerald"
        }
    }

    var subtitle: String {
        switch self {
        case .primary:
            return "Ana uygulama ikonu"
        case .crescentMinaret:
            return "Gold ve navy premium tema"
        case .modernClock:
            return "Modern vakit odaklı tasarım"
        case .monogramN:
            return "Sade monogram görünüm"
        case .ramadanGlow:
            return "Ramazan için parlak altın stil"
        case .emeraldMark:
            return "Yeşil premium alternatif"
        }
    }

    static func resolve(from iconName: String?) -> AppIconChoice {
        AppIconChoice.allCases.first(where: { $0.iconName == iconName }) ?? .primary
    }
}

enum DataSourceOption: String, CaseIterable, Identifiable {
    case diyanet = "Diyanet"
    case fallback = "Alternatif"

    var id: Self { self }
}

enum HadithSourceOption: String, CaseIterable, Identifiable {
    case contentPack = "Content Pack (Offline)"

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
            return "5 dk önce"
        case .tenMinutes:
            return "10 dk önce"
        case .fifteenMinutes:
            return "15 dk önce"
        case .thirtyMinutes:
            return "30 dk önce"
        }
    }
}

enum ReminderMode: String, CaseIterable, Identifiable {
    case notification = "Bildirim"
    case alarm = "Alarm"

    var id: Self { self }
}

enum AlarmTone: String, CaseIterable, Identifiable {
    case `default` = "Varsayılan"
    case ezanSoft = "Ezan Soft"
    case ezanClassic = "Ezan Klasik"
    case crystalBell = "Kristal Zil"
    case sereneNight = "Sakin Gece"
    case warmChime = "Yumuşak Çan"

    var id: Self { self }

    var fileName: String? {
        switch self {
        case .default:
            return nil
        case .ezanSoft:
            return "tone_ezan_soft.caf"
        case .ezanClassic:
            return "tone_ezan_classic.caf"
        case .crystalBell:
            return "tone_crystal_bell.caf"
        case .sereneNight:
            return "tone_serene_night.caf"
        case .warmChime:
            return "tone_warm_chime.caf"
        }
    }
}
