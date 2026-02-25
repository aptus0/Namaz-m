import Foundation

func countdownString(from start: Date, to end: Date) -> String {
    let totalSeconds = max(0, Int(end.timeIntervalSince(start)))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

func monthDays(for month: Date) -> [Date] {
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

func nextNDays(from reference: Date, count: Int) -> [Date] {
    let start = Calendar.current.startOfDay(for: reference)
    return (0..<count).compactMap {
        Calendar.current.date(byAdding: .day, value: $0, to: start)
    }
}
