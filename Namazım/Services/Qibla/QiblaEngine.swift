import Foundation
import CoreLocation

enum LocationQualityService {
    enum Status: Equatable {
        case high(CLLocationAccuracy)
        case medium(CLLocationAccuracy)
        case low(CLLocationAccuracy)
        case unavailable

        var value: CLLocationAccuracy? {
            switch self {
            case .high(let value), .medium(let value), .low(let value):
                return value
            case .unavailable:
                return nil
            }
        }
    }

    static func evaluate(location: CLLocation?) -> Status {
        guard let location else {
            return .unavailable
        }

        let accuracy = location.horizontalAccuracy
        guard accuracy >= 0 else {
            return .unavailable
        }

        if accuracy <= 25 {
            return .high(accuracy)
        }
        if accuracy <= 100 {
            return .medium(accuracy)
        }
        return .low(accuracy)
    }
}

enum HeadingQualityService {
    enum Status: Equatable {
        case precise(CLLocationDirection)
        case calibrationNeeded(CLLocationDirection)
        case unavailable

        var value: CLLocationDirection? {
            switch self {
            case .precise(let value), .calibrationNeeded(let value):
                return value
            case .unavailable:
                return nil
            }
        }
    }

    static func evaluate(accuracy: CLLocationDirection) -> Status {
        guard accuracy >= 0 else {
            return .unavailable
        }
        if accuracy <= 10 {
            return .precise(accuracy)
        }
        return .calibrationNeeded(accuracy)
    }
}

struct QiblaState: Equatable {
    let qiblaBearing: CLLocationDirection
    let currentHeading: CLLocationDirection
    let arrowRotation: CLLocationDirection
    let distanceToKaaba: CLLocationDistance
    let alignmentDelta: CLLocationDirection
    let isAligned: Bool
    let locationQuality: LocationQualityService.Status
    let headingQuality: HeadingQualityService.Status
    let isUsingTrueHeading: Bool
}

enum QiblaEngine {
    static let alignmentTolerance: CLLocationDirection = 3

    static func makeState(
        location: CLLocation?,
        heading: CLLocationDirection,
        headingAccuracy: CLLocationDirection,
        isUsingTrueHeading: Bool,
        tolerance: CLLocationDirection = alignmentTolerance
    ) -> QiblaState? {
        guard let location else {
            return nil
        }

        let qiblaBearing = QiblaCalculator.bearing(from: location.coordinate)
        let relative = QiblaCalculator.relativeAngle(qiblaBearing: qiblaBearing, heading: heading)
        let rotation = QiblaCalculator.signedAngle(relative)
        let delta = abs(QiblaCalculator.shortestDelta(from: heading, to: qiblaBearing))

        return QiblaState(
            qiblaBearing: qiblaBearing,
            currentHeading: heading,
            arrowRotation: rotation,
            distanceToKaaba: QiblaCalculator.distanceToKaaba(from: location.coordinate),
            alignmentDelta: delta,
            isAligned: delta <= tolerance,
            locationQuality: LocationQualityService.evaluate(location: location),
            headingQuality: HeadingQualityService.evaluate(accuracy: headingAccuracy),
            isUsingTrueHeading: isUsingTrueHeading
        )
    }
}
