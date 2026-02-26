import Foundation
import Combine
import CoreLocation
import CoreMotion
import UIKit

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var resolvedCity: String?
    @Published private(set) var heading: CLLocationDirection = 0
    @Published private(set) var headingAccuracy: CLLocationDirection = -1
    @Published private(set) var locationHorizontalAccuracy: CLLocationAccuracy = -1
    @Published private(set) var isUsingTrueHeading = true
    @Published private(set) var isLocating = false
    @Published private(set) var isHeadingActive = false
    @Published private(set) var deviceMotionActive = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let motionManager = CMMotionManager()

    private var isConfigured = false
    private var isQiblaTrackingActive = false
    private var hasDowngradedAccuracyAfterFix = false
    private var lastHeadingEmission = Date.distantPast
    private var smoothedHeading: CLLocationDirection?
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodeDate = Date.distantPast

    private let headingThrottleInterval: TimeInterval = 1.0 / 30.0
    private let headingMinimumDelta: CLLocationDirection = 0.5
    private let headingSmoothingFactor: Double = 0.22
    private let geocodeMinimumInterval: TimeInterval = 45

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = 1
        manager.activityType = .otherNavigation
        manager.pausesLocationUpdatesAutomatically = true

        authorizationStatus = manager.authorizationStatus
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUsePermission() {
        configureIfNeeded()
        manager.requestWhenInUseAuthorization()
    }

    func requestSingleLocation(forcePrecise: Bool = false) {
        configureIfNeeded()
        guard isAuthorized else {
            return
        }

        if forcePrecise {
            applyPreciseLocationProfile()
            hasDowngradedAccuracyAfterFix = false
        }

        isLocating = true
        manager.requestLocation()
    }

    func startQiblaTracking() {
        configureIfNeeded()
        guard isAuthorized else { return }

        isQiblaTrackingActive = true
        hasDowngradedAccuracyAfterFix = false

        applyPreciseLocationProfile()
        manager.startUpdatingLocation()
        requestSingleLocation(forcePrecise: true)
        startHeadingUpdates()
    }

    func stopQiblaTracking() {
        isQiblaTrackingActive = false
        hasDowngradedAccuracyAfterFix = false
        manager.stopUpdatingLocation()
        stopHeadingUpdates()
    }

    func startHeadingUpdates() {
        configureIfNeeded()
        guard isAuthorized else { return }
        guard CLLocationManager.headingAvailable() else { return }

        if isHeadingActive {
            return
        }

        isHeadingActive = true
        smoothedHeading = nil
        lastHeadingEmission = .distantPast
        manager.startUpdatingHeading()
        startDeviceMotion()
    }

    func stopHeadingUpdates() {
        guard isHeadingActive else {
            return
        }

        isHeadingActive = false
        manager.stopUpdatingHeading()
        smoothedHeading = nil
        headingAccuracy = -1
        stopDeviceMotion()
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var statusDescription: String {
        let base: String
        switch authorizationStatus {
        case .notDetermined:
            base = "Konum izni bekleniyor"
        case .restricted:
            base = "Konum izni kısıtlı"
        case .denied:
            base = "Konum izni kapalı"
        case .authorizedAlways:
            base = "Konum izni (Always) açık"
        case .authorizedWhenInUse:
            base = "Konum izni açık"
        @unknown default:
            base = "Konum durumu bilinmiyor"
        }

        guard locationHorizontalAccuracy > 0 else {
            return base
        }
        return "\(base)  •  ±\(Int(locationHorizontalAccuracy.rounded()))m"
    }

    private func handleLocation(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0 else {
            return
        }

        currentLocation = location
        locationHorizontalAccuracy = location.horizontalAccuracy
        isLocating = false

        if isQiblaTrackingActive,
           !hasDowngradedAccuracyAfterFix,
           location.horizontalAccuracy <= 25 {
            applyPowerSavingLocationProfile()
            hasDowngradedAccuracyAfterFix = true
        }

        if shouldResolveCity(for: location) {
            resolveCity(from: location)
        }
    }

    private func resolveCity(from location: CLLocation) {
        lastGeocodeDate = Date()
        lastGeocodedLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            guard let placemark = placemarks?.first else { return }

            let city = placemark.administrativeArea ?? placemark.locality ?? placemark.subAdministrativeArea
            Task { @MainActor in
                self.resolvedCity = city
            }
        }
    }

    private func shouldResolveCity(for location: CLLocation) -> Bool {
        guard Date().timeIntervalSince(lastGeocodeDate) >= geocodeMinimumInterval else {
            return false
        }

        guard let previous = lastGeocodedLocation else {
            return true
        }

        return location.distance(from: previous) >= 1_500
    }

    private func applyPreciseLocationProfile() {
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    private func applyPowerSavingLocationProfile() {
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 20
    }

    private func publishHeading(rawValue: CLLocationDirection, accuracy: CLLocationDirection, isTrueHeading: Bool) {
        headingAccuracy = accuracy
        isUsingTrueHeading = isTrueHeading

        guard rawValue >= 0 else {
            return
        }

        let now = Date()
        guard now.timeIntervalSince(lastHeadingEmission) >= headingThrottleInterval else {
            return
        }

        let previous = smoothedHeading
        let filtered = filteredHeading(for: rawValue)
        if let previous {
            let delta = abs(QiblaCalculator.shortestDelta(from: previous, to: filtered))
            if delta < headingMinimumDelta {
                return
            }
        }

        heading = filtered
        lastHeadingEmission = now
    }

    private func filteredHeading(for rawValue: CLLocationDirection) -> CLLocationDirection {
        guard let previous = smoothedHeading else {
            smoothedHeading = QiblaCalculator.normalizedHeading(rawValue)
            return smoothedHeading ?? rawValue
        }

        let delta = QiblaCalculator.shortestDelta(from: previous, to: rawValue)
        let next = QiblaCalculator.normalizedHeading(previous + (delta * headingSmoothingFactor))
        smoothedHeading = next
        return next
    }

    private func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            deviceMotionActive = false
            return
        }

        if motionManager.isDeviceMotionActive {
            deviceMotionActive = true
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates()
        deviceMotionActive = true
    }

    private func stopDeviceMotion() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        deviceMotionActive = false
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.requestSingleLocation()
            } else {
                self.stopQiblaTracking()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }

        let freshLocations = locations.filter { abs($0.timestamp.timeIntervalSinceNow) <= 20 }
        let candidatePool = freshLocations.isEmpty ? locations : freshLocations
        let location = candidatePool.min { lhs, rhs in
            let lhsAccuracy = lhs.horizontalAccuracy >= 0 ? lhs.horizontalAccuracy : .greatestFiniteMagnitude
            let rhsAccuracy = rhs.horizontalAccuracy >= 0 ? rhs.horizontalAccuracy : .greatestFiniteMagnitude
            return lhsAccuracy < rhsAccuracy
        }

        guard let location else { return }
        Task { @MainActor in
            self.handleLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            if let clError = error as? CLError, clError.code == .locationUnknown {
                return
            }
            print("Location error: \(error)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let usesTrueHeading = newHeading.trueHeading >= 0
        let headingValue = usesTrueHeading ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.publishHeading(rawValue: headingValue, accuracy: newHeading.headingAccuracy, isTrueHeading: usesTrueHeading)
        }
    }
}
