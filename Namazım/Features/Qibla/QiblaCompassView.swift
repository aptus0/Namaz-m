import SwiftUI
import CoreLocation
import UIKit

struct QiblaCompassView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    private var qiblaBearing: CLLocationDirection? {
        guard let coordinate = locationManager.currentLocation?.coordinate else { return nil }
        return QiblaCalculator.bearing(from: coordinate)
    }

    private var relativeAngle: CLLocationDirection? {
        guard let qiblaBearing else { return nil }
        return QiblaCalculator.relativeAngle(qiblaBearing: qiblaBearing, heading: locationManager.heading)
    }

    private var isAligned: Bool {
        guard let relativeAngle else { return false }
        return QiblaCalculator.isAligned(relativeAngle: relativeAngle)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Secili Il: \(appState.selectedCity)")
                        .font(.headline)

                    Text(locationManager.statusDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let qiblaBearing {
                        Text("Kible acisi: \(Int(qiblaBearing))°")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .premiumCardStyle()

                ZStack {
                    Circle()
                        .stroke(PremiumPalette.navy.opacity(0.14), lineWidth: 22)
                        .frame(width: 280, height: 280)

                    Circle()
                        .stroke(PremiumPalette.gold.opacity(0.40), lineWidth: 6)
                        .frame(width: 240, height: 240)

                    Image(systemName: "location.north.fill")
                        .font(.system(size: 82, weight: .bold))
                        .foregroundStyle(isAligned ? .green : PremiumPalette.navy)
                        .rotationEffect(.degrees(relativeAngle ?? 0))
                        .animation(.easeInOut(duration: 0.2), value: relativeAngle)

                    VStack {
                        Text(isAligned ? "Kibleye Hizalandi" : "Kibleye Don")
                            .font(.headline)
                            .foregroundStyle(isAligned ? .green : .secondary)

                        Text("Heading: \(Int(locationManager.heading))°")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .offset(y: 165)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)

                HStack(spacing: 10) {
                    Button("Konumu Al") {
                        locationManager.requestSingleLocation()
                    }
                    .buttonStyle(.bordered)

                    Button("Ayarlar") {
                        locationManager.openAppSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Kible Pusula")
        .premiumScreenBackground()
        .onAppear {
            locationManager.startHeadingUpdates()
            locationManager.requestSingleLocation()
        }
        .onDisappear {
            locationManager.stopHeadingUpdates()
        }
        .onChange(of: locationManager.resolvedCity) { _, city in
            appState.applyDetectedCity(city)
        }
        .onChange(of: isAligned) { oldValue, newValue in
            if !oldValue && newValue {
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
            }
        }
    }
}
