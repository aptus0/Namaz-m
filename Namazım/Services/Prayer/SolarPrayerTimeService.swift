import Foundation

enum SolarPrayerTimeService {
    private struct SolarEvent {
        let sunrise: Date
        let sunset: Date
    }

    static func entries(for city: WorldCity, day: Date = Date()) -> [PrayerEntry] {
        guard let solar = solarEvents(for: city, day: day) else {
            return fallbackEntries(for: city, day: day)
        }

        let sunrise = solar.sunrise
        let sunset = solar.sunset
        let midday = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) / 2)
        let afternoon = midday.addingTimeInterval(max(2.5 * 3600, sunset.timeIntervalSince(midday) * 0.55))

        let entries: [PrayerEntry] = [
            PrayerEntry(prayer: .imsak, date: sunrise.addingTimeInterval(-90 * 60)),
            PrayerEntry(prayer: .gunes, date: sunrise),
            PrayerEntry(prayer: .ogle, date: midday),
            PrayerEntry(prayer: .ikindi, date: min(afternoon, sunset.addingTimeInterval(-75 * 60))),
            PrayerEntry(prayer: .aksam, date: sunset),
            PrayerEntry(prayer: .yatsi, date: sunset.addingTimeInterval(90 * 60))
        ]

        return entries.sorted { $0.date < $1.date }
    }

    static func timeline(for city: WorldCity, now: Date = Date()) -> PrayerTimeline {
        let calendar = Calendar(identifier: .gregorian)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now

        let all = (entries(for: city, day: yesterday) + entries(for: city, day: now) + entries(for: city, day: tomorrow))
            .sorted { $0.date < $1.date }

        guard let nextIndex = all.firstIndex(where: { $0.date > now }) else {
            let todayEntries = entries(for: city, day: now)
            return PrayerTimeline(previous: todayEntries[max(todayEntries.count - 2, 0)], next: todayEntries[max(todayEntries.count - 1, 0)])
        }

        let previous = all[max(0, nextIndex - 1)]
        let next = all[nextIndex]
        return PrayerTimeline(previous: previous, next: next)
    }

    static func snapshot(for city: WorldCity, now: Date = Date(), language: AppLanguage) -> WorldCityPrayerSnapshot {
        let timeline = timeline(for: city, now: now)
        let localTime = format(date: now, in: city.timeZone, locale: language.locale, template: "HH:mm")
        let nextPrayerTime = format(date: timeline.next.date, in: city.timeZone, locale: language.locale, template: "HH:mm")
        let zoneLabel = zoneDisplayName(for: city.timeZone)

        return WorldCityPrayerSnapshot(
            city: city,
            localTime: localTime,
            nextPrayerName: timeline.next.prayer.localizedTitle(language: language),
            nextPrayerTime: nextPrayerTime,
            remaining: countdownString(from: now, to: timeline.next.date),
            timeZoneLabel: zoneLabel
        )
    }

    private static func fallbackEntries(for city: WorldCity, day: Date) -> [PrayerEntry] {
        let localDefinitions: [(PrayerName, Int, Int)] = [
            (.imsak, 5, 30),
            (.gunes, 7, 0),
            (.ogle, 12, 55),
            (.ikindi, 16, 20),
            (.aksam, 19, 5),
            (.yatsi, 20, 30)
        ]

        let calendar = Calendar(identifier: .gregorian)

        return localDefinitions.compactMap { definition in
            var components = calendar.dateComponents(in: city.timeZone, from: day)
            components.timeZone = city.timeZone
            components.hour = definition.1
            components.minute = definition.2
            components.second = 0
            return calendar.date(from: components).map { PrayerEntry(prayer: definition.0, date: $0) }
        }
    }

    private static func solarEvents(for city: WorldCity, day: Date) -> SolarEvent? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = city.timeZone
        let localDay = calendar.startOfDay(for: day)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: localDay) ?? 1

        guard
            let sunriseUT = sunTimeUTC(dayOfYear: dayOfYear, latitude: city.latitude, longitude: city.longitude, isSunrise: true),
            let sunsetUT = sunTimeUTC(dayOfYear: dayOfYear, latitude: city.latitude, longitude: city.longitude, isSunrise: false)
        else {
            return nil
        }

        let tzOffsetHours = Double(city.timeZone.secondsFromGMT(for: localDay)) / 3600

        guard
            let sunrise = date(for: localDay, localHour: sunriseUT + tzOffsetHours, timeZone: city.timeZone),
            let sunset = date(for: localDay, localHour: sunsetUT + tzOffsetHours, timeZone: city.timeZone)
        else {
            return nil
        }

        return SolarEvent(sunrise: sunrise, sunset: sunset)
    }

    private static func sunTimeUTC(dayOfYear: Int, latitude: Double, longitude: Double, isSunrise: Bool) -> Double? {
        let zenith = 90.833
        let lngHour = longitude / 15

        let approximateTime = Double(dayOfYear) + ((isSunrise ? 6.0 : 18.0) - lngHour) / 24

        let meanAnomaly = (0.9856 * approximateTime) - 3.289

        var trueLongitude = meanAnomaly + (1.916 * sin(degreesToRadians(meanAnomaly)))
        trueLongitude += 0.020 * sin(2 * degreesToRadians(meanAnomaly))
        trueLongitude += 282.634
        trueLongitude = normalize(trueLongitude, modulo: 360)

        var rightAscension = radiansToDegrees(atan(0.91764 * tan(degreesToRadians(trueLongitude))))
        rightAscension = normalize(rightAscension, modulo: 360)

        let lQuadrant = floor(trueLongitude / 90) * 90
        let raQuadrant = floor(rightAscension / 90) * 90
        rightAscension += (lQuadrant - raQuadrant)
        rightAscension /= 15

        let sinDeclination = 0.39782 * sin(degreesToRadians(trueLongitude))
        let cosDeclination = cos(asin(sinDeclination))

        let cosHourAngle = (
            cos(degreesToRadians(zenith))
            - (sinDeclination * sin(degreesToRadians(latitude)))
        ) / (cosDeclination * cos(degreesToRadians(latitude)))

        if cosHourAngle > 1 || cosHourAngle < -1 {
            return nil
        }

        var hourAngle = isSunrise
            ? 360 - radiansToDegrees(acos(cosHourAngle))
            : radiansToDegrees(acos(cosHourAngle))

        hourAngle /= 15

        let localMeanTime = hourAngle + rightAscension - (0.06571 * approximateTime) - 6.622
        return normalize(localMeanTime - lngHour, modulo: 24)
    }

    private static func date(for localDay: Date, localHour: Double, timeZone: TimeZone) -> Date? {
        let secondsPerDay = 24 * 3600
        var totalSeconds = Int(round(localHour * 3600))
        var dayShift = 0

        while totalSeconds < 0 {
            totalSeconds += secondsPerDay
            dayShift -= 1
        }

        while totalSeconds >= secondsPerDay {
            totalSeconds -= secondsPerDay
            dayShift += 1
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let adjustedDay = calendar.date(byAdding: .day, value: dayShift, to: localDay) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: adjustedDay)
        components.timeZone = timeZone
        components.hour = totalSeconds / 3600
        components.minute = (totalSeconds % 3600) / 60
        components.second = totalSeconds % 60

        return calendar.date(from: components)
    }

    private static func format(date: Date, in timeZone: TimeZone, locale: Locale, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    private static func zoneDisplayName(for timeZone: TimeZone) -> String {
        if let short = timeZone.abbreviation() {
            return "\(short) · \(timeZone.identifier)"
        }
        return timeZone.identifier
    }

    private static func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }

    private static func radiansToDegrees(_ value: Double) -> Double {
        value * 180 / .pi
    }

    private static func normalize(_ value: Double, modulo: Double) -> Double {
        var normalized = value.truncatingRemainder(dividingBy: modulo)
        if normalized < 0 {
            normalized += modulo
        }
        return normalized
    }
}
