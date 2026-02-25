import Foundation
import CoreLocation

enum QiblaCalculator {
    private static let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    static func bearing(from coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = coordinate.latitude.radians
        let lon1 = coordinate.longitude.radians
        let lat2 = kaabaCoordinate.latitude.radians
        let lon2 = kaabaCoordinate.longitude.radians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansBearing.degrees.normalizedHeading
    }

    static func relativeAngle(qiblaBearing: CLLocationDirection, heading: CLLocationDirection) -> CLLocationDirection {
        (qiblaBearing - heading).normalizedHeading
    }

    static func isAligned(relativeAngle: CLLocationDirection, tolerance: CLLocationDirection = 3) -> Bool {
        let normalized = relativeAngle.normalizedHeading
        return normalized <= tolerance || normalized >= (360 - tolerance)
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }

    var normalizedHeading: Double {
        var value = self.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }
}
