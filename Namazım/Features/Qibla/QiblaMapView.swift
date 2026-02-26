import SwiftUI
import MapKit
import CoreLocation

private struct QiblaMapMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
        }
    }
}

struct QiblaMapView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.0, longitude: 24.0),
        span: MKCoordinateSpan(latitudeDelta: 72.0, longitudeDelta: 82.0)
    )

    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)
    @State private var hasPositionedCamera = false

    private var qiblaState: QiblaState? {
        QiblaEngine.makeState(
            location: locationManager.currentLocation,
            heading: locationManager.heading,
            headingAccuracy: locationManager.headingAccuracy,
            isUsingTrueHeading: locationManager.isUsingTrueHeading
        )
    }

    private var userCoordinate: CLLocationCoordinate2D? {
        locationManager.currentLocation?.coordinate
    }

    private var geodesicRoute: MKGeodesicPolyline? {
        guard let userCoordinate else {
            return nil
        }

        var coordinates = [userCoordinate, QiblaCalculator.kaabaCoordinate]
        return MKGeodesicPolyline(coordinates: &coordinates, count: coordinates.count)
    }

    private var locationBadge: (text: String, color: Color) {
        switch qiblaState?.locationQuality ?? .unavailable {
        case .high(let accuracy):
            return ("GPS ±\(Int(accuracy.rounded()))m", .green)
        case .medium(let accuracy):
            return ("GPS ±\(Int(accuracy.rounded()))m", .orange)
        case .low(let accuracy):
            return ("GPS ±\(Int(accuracy.rounded()))m", .red)
        case .unavailable:
            return ("GPS bekleniyor", .secondary)
        }
    }

    private var alignmentBadge: (text: String, color: Color) {
        if qiblaState?.isAligned == true {
            return ("Hizalı", .green)
        }
        return ("Hizalama bekleniyor", .orange)
    }

    private var cityTitle: String {
        locationManager.resolvedCity ?? appState.selectedCity
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Kıble Haritası")
                        .font(.title3.weight(.bold))
                    Spacer()
                    Text(cityTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    badge(text: locationBadge.text, color: locationBadge.color)
                    badge(text: alignmentBadge.text, color: alignmentBadge.color)
                }

                Text("Kâbe ile bulunduğunuz konum arasındaki büyük çember hattı gösterilir.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .premiumCardStyle()
            .padding(.horizontal)

            if let userCoordinate {
                Map(position: $cameraPosition) {
                    if let geodesicRoute {
                        MapPolyline(geodesicRoute)
                            .stroke(
                                PremiumPalette.gold,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6])
                            )
                    }

                    Annotation("Konumunuz", coordinate: userCoordinate, anchor: .center) {
                        VStack(spacing: 4) {
                            Image(systemName: "location.north.circle.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.green)
                                .rotationEffect(.degrees(qiblaState?.qiblaBearing ?? 0))

                            Text("\(Int((qiblaState?.qiblaBearing ?? 0).rounded()))°")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule(style: .continuous).fill(.ultraThinMaterial))
                        }
                    }

                    Annotation("Kâbe", coordinate: QiblaCalculator.kaabaCoordinate, anchor: .bottom) {
                        VStack(spacing: 4) {
                            Image(systemName: "building.columns.circle.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(PremiumPalette.gold)

                            Text("Kâbe")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule(style: .continuous).fill(.ultraThinMaterial))
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Konum alınıyor...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(spacing: 12) {
                QiblaMapMetricRow(
                    title: "Kıble Açısı",
                    value: "\(Int((qiblaState?.qiblaBearing ?? 0).rounded()))°"
                )
                QiblaMapMetricRow(
                    title: "Kâbe Mesafesi",
                    value: distanceText(qiblaState?.distanceToKaaba)
                )
                QiblaMapMetricRow(
                    title: "Hizalama",
                    value: qiblaState?.isAligned == true ? "Tam hizalı" : "Dönüş gerekli"
                )
                QiblaMapMetricRow(
                    title: "Sensör",
                    value: (qiblaState?.isUsingTrueHeading ?? locationManager.isUsingTrueHeading) ? "True Heading" : "Manyetik Heading"
                )
            }
            .premiumCardStyle()
            .padding(.horizontal)

            HStack(spacing: 10) {
                Button("Konumu Yenile") {
                    hasPositionedCamera = false
                    locationManager.requestSingleLocation(forcePrecise: true)
                }
                .buttonStyle(.borderedProminent)

                Button("Ayarlar") {
                    locationManager.openAppSettings()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom)
        }
        .navigationTitle("Kıble Harita")
        .premiumScreenBackground()
        .onAppear {
            locationManager.startQiblaTracking()
            locationManager.requestSingleLocation(forcePrecise: true)
            centerCameraIfNeeded(force: false)
        }
        .onDisappear {
            locationManager.stopQiblaTracking()
        }
        .onChange(of: locationManager.currentLocation?.coordinate.latitude) { _, _ in
            centerCameraIfNeeded(force: false)
        }
        .onChange(of: locationManager.currentLocation?.coordinate.longitude) { _, _ in
            centerCameraIfNeeded(force: false)
        }
        .onChange(of: locationManager.resolvedCity) { _, city in
            appState.applyDetectedCity(city)
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.16))
            )
            .foregroundStyle(color)
    }

    private func centerCameraIfNeeded(force: Bool) {
        guard let userCoordinate else {
            return
        }

        guard force || !hasPositionedCamera else {
            return
        }

        hasPositionedCamera = true
        let region = makeWorldRegion(for: userCoordinate)
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(region)
        }
    }

    private func makeWorldRegion(for userCoordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let kaaba = QiblaCalculator.kaabaCoordinate

        let center = CLLocationCoordinate2D(
            latitude: (userCoordinate.latitude + kaaba.latitude) / 2,
            longitude: (userCoordinate.longitude + kaaba.longitude) / 2
        )

        let latitudeDelta = min(max(abs(userCoordinate.latitude - kaaba.latitude) * 1.9, 8), 170)
        let longitudeDelta = min(max(abs(userCoordinate.longitude - kaaba.longitude) * 1.9, 8), 350)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    private func distanceText(_ meters: CLLocationDistance?) -> String {
        guard let meters, meters > 0 else {
            return "--"
        }

        let kilometers = meters / 1_000
        if kilometers >= 100 {
            return "\(Int(kilometers.rounded())) km"
        }
        return String(format: "%.1f km", kilometers)
    }
}
