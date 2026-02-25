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
    @Published private(set) var isLocating = false
    @Published private(set) var isHeadingActive = false
    @Published private(set) var deviceMotionActive = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let motionManager = CMMotionManager()

    private var isConfigured = false

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = 1

        authorizationStatus = manager.authorizationStatus
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUsePermission() {
        configureIfNeeded()
        manager.requestWhenInUseAuthorization()
    }

    func requestSingleLocation() {
        configureIfNeeded()
        guard isAuthorized else {
            return
        }

        isLocating = true
        manager.requestLocation()
    }

    func startHeadingUpdates() {
        configureIfNeeded()
        guard isAuthorized else { return }
        guard CLLocationManager.headingAvailable() else { return }

        isHeadingActive = true
        manager.startUpdatingHeading()
        startDeviceMotion()
    }

    func stopHeadingUpdates() {
        isHeadingActive = false
        manager.stopUpdatingHeading()
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
        switch authorizationStatus {
        case .notDetermined:
            return "Konum izni bekleniyor"
        case .restricted:
            return "Konum izni kisitli"
        case .denied:
            return "Konum izni kapali"
        case .authorizedAlways:
            return "Konum izni (Always) acik"
        case .authorizedWhenInUse:
            return "Konum izni acik"
        @unknown default:
            return "Konum durumu bilinmiyor"
        }
    }

    private func handleLocation(_ location: CLLocation) {
        currentLocation = location
        isLocating = false
        resolveCity(from: location)
    }

    private func resolveCity(from location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            guard let placemark = placemarks?.first else { return }

            let city = placemark.administrativeArea ?? placemark.locality ?? placemark.subAdministrativeArea
            Task { @MainActor in
                self.resolvedCity = city
            }
        }
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
                self.stopHeadingUpdates()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.handleLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            print("Location error: \(error)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let headingValue = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.heading = headingValue
        }
    }
}
