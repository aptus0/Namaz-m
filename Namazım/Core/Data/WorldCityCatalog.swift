import Foundation

enum WorldCityCatalog {
    static let all: [WorldCity] = [
        WorldCity(id: "istanbul", name: "İstanbul", countryCode: "TR", timeZoneID: "Europe/Istanbul", latitude: 41.0082, longitude: 28.9784),
        WorldCity(id: "ankara", name: "Ankara", countryCode: "TR", timeZoneID: "Europe/Istanbul", latitude: 39.9334, longitude: 32.8597),
        WorldCity(id: "izmir", name: "İzmir", countryCode: "TR", timeZoneID: "Europe/Istanbul", latitude: 38.4237, longitude: 27.1428),
        WorldCity(id: "kocaeli", name: "Kocaeli", countryCode: "TR", timeZoneID: "Europe/Istanbul", latitude: 40.7654, longitude: 29.9408),
        WorldCity(id: "makkah", name: "Makkah", countryCode: "SA", timeZoneID: "Asia/Riyadh", latitude: 21.3891, longitude: 39.8579),
        WorldCity(id: "medina", name: "Medina", countryCode: "SA", timeZoneID: "Asia/Riyadh", latitude: 24.5247, longitude: 39.5692),
        WorldCity(id: "dubai", name: "Dubai", countryCode: "AE", timeZoneID: "Asia/Dubai", latitude: 25.2048, longitude: 55.2708),
        WorldCity(id: "doha", name: "Doha", countryCode: "QA", timeZoneID: "Asia/Qatar", latitude: 25.2854, longitude: 51.5310),
        WorldCity(id: "london", name: "London", countryCode: "GB", timeZoneID: "Europe/London", latitude: 51.5072, longitude: -0.1276),
        WorldCity(id: "paris", name: "Paris", countryCode: "FR", timeZoneID: "Europe/Paris", latitude: 48.8566, longitude: 2.3522),
        WorldCity(id: "berlin", name: "Berlin", countryCode: "DE", timeZoneID: "Europe/Berlin", latitude: 52.5200, longitude: 13.4050),
        WorldCity(id: "vienna", name: "Vienna", countryCode: "AT", timeZoneID: "Europe/Vienna", latitude: 48.2082, longitude: 16.3738),
        WorldCity(id: "new-york", name: "New York", countryCode: "US", timeZoneID: "America/New_York", latitude: 40.7128, longitude: -74.0060),
        WorldCity(id: "chicago", name: "Chicago", countryCode: "US", timeZoneID: "America/Chicago", latitude: 41.8781, longitude: -87.6298),
        WorldCity(id: "los-angeles", name: "Los Angeles", countryCode: "US", timeZoneID: "America/Los_Angeles", latitude: 34.0522, longitude: -118.2437),
        WorldCity(id: "toronto", name: "Toronto", countryCode: "CA", timeZoneID: "America/Toronto", latitude: 43.6532, longitude: -79.3832),
        WorldCity(id: "cairo", name: "Cairo", countryCode: "EG", timeZoneID: "Africa/Cairo", latitude: 30.0444, longitude: 31.2357),
        WorldCity(id: "johannesburg", name: "Johannesburg", countryCode: "ZA", timeZoneID: "Africa/Johannesburg", latitude: -26.2041, longitude: 28.0473),
        WorldCity(id: "karachi", name: "Karachi", countryCode: "PK", timeZoneID: "Asia/Karachi", latitude: 24.8607, longitude: 67.0011),
        WorldCity(id: "lahore", name: "Lahore", countryCode: "PK", timeZoneID: "Asia/Karachi", latitude: 31.5204, longitude: 74.3587),
        WorldCity(id: "jakarta", name: "Jakarta", countryCode: "ID", timeZoneID: "Asia/Jakarta", latitude: -6.2088, longitude: 106.8456),
        WorldCity(id: "kuala-lumpur", name: "Kuala Lumpur", countryCode: "MY", timeZoneID: "Asia/Kuala_Lumpur", latitude: 3.1390, longitude: 101.6869),
        WorldCity(id: "singapore", name: "Singapore", countryCode: "SG", timeZoneID: "Asia/Singapore", latitude: 1.3521, longitude: 103.8198),
        WorldCity(id: "tokyo", name: "Tokyo", countryCode: "JP", timeZoneID: "Asia/Tokyo", latitude: 35.6762, longitude: 139.6503),
        WorldCity(id: "sydney", name: "Sydney", countryCode: "AU", timeZoneID: "Australia/Sydney", latitude: -33.8688, longitude: 151.2093)
    ]

    static let defaultCityIDs: [String] = ["istanbul", "makkah", "london", "new-york"]

    static func city(id: String) -> WorldCity? {
        all.first(where: { $0.id == id })
    }

    static func search(_ query: String, excluding excludedIDs: Set<String> = []) -> [WorldCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let pool = all.filter { !excludedIDs.contains($0.id) }

        guard !trimmed.isEmpty else {
            return pool
        }

        let normalizedQuery = normalize(trimmed)

        return pool.filter { city in
            normalize(city.name).contains(normalizedQuery)
            || normalize(city.countryCode).contains(normalizedQuery)
            || normalize(city.timeZoneID).contains(normalizedQuery)
        }
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: " ", with: "")
    }
}
