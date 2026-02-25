import SwiftUI
import MapKit
import CoreLocation

private struct QiblaMapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let bearing: CLLocationDirection
}

struct QiblaMapView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    private var annotationItems: [QiblaMapAnnotation] {
        guard let coordinate = locationManager.currentLocation?.coordinate else { return [] }
        let bearing = QiblaCalculator.bearing(from: coordinate)
        return [QiblaMapAnnotation(coordinate: coordinate, bearing: bearing)]
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kible Haritasi")
                    .font(.headline)
                Text("Konum: \(appState.selectedCity)")
                    .font(.subheadline)
                Text("Yesil ok Kible yonunu gosterir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .premiumCardStyle()
            .padding(.horizontal)

            if annotationItems.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Konum aliniyor...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Map(coordinateRegion: $region, annotationItems: annotationItems) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "location.north.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.green)
                                .rotationEffect(.degrees(item.bearing))

                            Text("\(Int(item.bearing))°")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal)
            }

            HStack(spacing: 10) {
                Button("Konumu Yenile") {
                    locationManager.requestSingleLocation()
                }
                .buttonStyle(.bordered)

                Button("Ayarlar") {
                    locationManager.openAppSettings()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom)
        }
        .navigationTitle("Kible Harita")
        .premiumScreenBackground()
        .onAppear {
            locationManager.requestSingleLocation()
        }
        .onChange(of: locationManager.currentLocation) { _, location in
            guard let coordinate = location?.coordinate else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                region.center = coordinate
            }
        }
        .onChange(of: locationManager.resolvedCity) { _, city in
            appState.applyDetectedCity(city)
        }
    }
}
