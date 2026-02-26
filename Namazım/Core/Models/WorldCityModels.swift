import Foundation

struct WorldCity: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let countryCode: String
    let timeZoneID: String
    let latitude: Double
    let longitude: Double

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneID) ?? .current
    }
}

struct WorldCityPrayerSnapshot: Identifiable, Hashable {
    let city: WorldCity
    let localTime: String
    let nextPrayerName: String
    let nextPrayerTime: String
    let remaining: String
    let timeZoneLabel: String

    var id: String { city.id }
}
