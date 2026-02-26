import Foundation

enum HijriCalendarService {
    private static let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    static func fullHijriDateString(for date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.locale = locale
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    static func dayNumber(for date: Date) -> Int {
        hijriCalendar.component(.day, from: date)
    }

    static func monthNumber(for date: Date) -> Int {
        hijriCalendar.component(.month, from: date)
    }

    static func specialDayKey(for date: Date) -> String? {
        let day = dayNumber(for: date)
        let month = monthNumber(for: date)

        switch (month, day) {
        case (1, 1):
            return "hijri_special_new_year"
        case (1, 10):
            return "hijri_special_ashura"
        case (3, 12):
            return "hijri_special_mawlid"
        case (7, 27):
            return "hijri_special_miraj"
        case (8, 15):
            return "hijri_special_baraat"
        case (9, 1):
            return "hijri_special_ramadan_start"
        case (9, 27):
            return "hijri_special_qadr"
        case (10, 1):
            return "hijri_special_eid_fitr"
        case (12, 10):
            return "hijri_special_eid_adha"
        default:
            return nil
        }
    }
}
