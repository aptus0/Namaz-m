import SwiftUI
import CoreLocation
import UIKit

private struct QiblaMetricRow: View {
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

struct QiblaCompassView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    @State private var lastAlignmentHapticDate = Date.distantPast

    private var qiblaState: QiblaState? {
        QiblaEngine.makeState(
            location: locationManager.currentLocation,
            heading: locationManager.heading,
            headingAccuracy: locationManager.headingAccuracy,
            isUsingTrueHeading: locationManager.isUsingTrueHeading
        )
    }

    private var locationQuality: LocationQualityService.Status {
        qiblaState?.locationQuality ?? .unavailable
    }

    private var headingQuality: HeadingQualityService.Status {
        qiblaState?.headingQuality ?? .unavailable
    }

    private var alignmentText: String {
        if qiblaState?.isAligned == true {
            return "Kıble hizalandı"
        }
        return "Kıbleye dön"
    }

    private var locationBadge: (text: String, color: Color) {
        switch locationQuality {
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

    private var headingBadge: (text: String, color: Color) {
        switch headingQuality {
        case .precise(let accuracy):
            return ("Pusula ±\(Int(accuracy.rounded()))°", .green)
        case .calibrationNeeded(let accuracy):
            return ("Kalibrasyon ±\(Int(accuracy.rounded()))°", .orange)
        case .unavailable:
            return ("Pusula bekleniyor", .secondary)
        }
    }

    private var guidanceText: String? {
        if case .low = locationQuality {
            return "Konum hassasiyeti düşük. Konumu yenileyin ve açık alanda yeniden deneyin."
        }

        if case .calibrationNeeded = headingQuality {
            return "Pusulayı kalibre etmek için telefonu 8 çizerek hareket ettirin."
        }

        if case .unavailable = headingQuality {
            return "Pusula verisi alınamadı. Cihaz hareket sensörlerini kontrol edin."
        }

        return nil
    }

    private var cityTitle: String {
        locationManager.resolvedCity ?? appState.selectedCity
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Kıble Pusulası")
                            .font(.title3.weight(.bold))
                        Spacer()
                        Text(cityTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        badge(text: locationBadge.text, color: locationBadge.color)
                        badge(text: headingBadge.text, color: headingBadge.color)
                    }

                    if let guidanceText {
                        Text(guidanceText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(locationManager.statusDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .premiumCardStyle()

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(PremiumPalette.heroGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )

                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.18), lineWidth: 22)
                            .frame(width: 286, height: 286)

                        Circle()
                            .stroke(PremiumPalette.gold.opacity(0.48), lineWidth: 4)
                            .frame(width: 230, height: 230)

                        ForEach(0..<72, id: \.self) { index in
                            Capsule(style: .continuous)
                                .fill(index.isMultiple(of: 6) ? .white.opacity(0.56) : .white.opacity(0.24))
                                .frame(width: 2, height: index.isMultiple(of: 6) ? 14 : 8)
                                .offset(y: -136)
                                .rotationEffect(.degrees(Double(index) * 5))
                        }

                        Image(systemName: "location.north.fill")
                            .font(.system(size: 78, weight: .bold))
                            .foregroundStyle(qiblaState?.isAligned == true ? .green : PremiumPalette.gold)
                            .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 4)
                            .rotationEffect(.degrees(qiblaState?.arrowRotation ?? 0))
                            .animation(.linear(duration: 0.10), value: qiblaState?.arrowRotation ?? 0)

                        VStack(spacing: 8) {
                            Text(alignmentText)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)

                            Text("Fark: \(Int((qiblaState?.alignmentDelta ?? 0).rounded()))°")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .offset(y: 112)
                    }
                    .padding(.vertical, 12)
                }
                .frame(height: 360)

                VStack(spacing: 12) {
                    QiblaMetricRow(
                        title: "Kıble Açısı",
                        value: "\(Int((qiblaState?.qiblaBearing ?? 0).rounded()))°"
                    )
                    QiblaMetricRow(
                        title: "Cihaz Yönü",
                        value: "\(Int((qiblaState?.currentHeading ?? locationManager.heading).rounded()))°"
                    )
                    QiblaMetricRow(
                        title: "Kâbe Mesafesi",
                        value: distanceText(qiblaState?.distanceToKaaba)
                    )
                    QiblaMetricRow(
                        title: "Sensör Modu",
                        value: (qiblaState?.isUsingTrueHeading ?? locationManager.isUsingTrueHeading) ? "True Heading" : "Manyetik Heading"
                    )
                }
                .premiumCardStyle()

                HStack(spacing: 10) {
                    Button("Konumu Yenile") {
                        locationManager.requestSingleLocation(forcePrecise: true)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Ayarlar") {
                        locationManager.openAppSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Kıble")
        .premiumScreenBackground()
        .onAppear {
            locationManager.startQiblaTracking()
        }
        .onDisappear {
            locationManager.stopQiblaTracking()
        }
        .onChange(of: locationManager.resolvedCity) { _, city in
            appState.applyDetectedCity(city)
        }
        .onChange(of: qiblaState?.isAligned ?? false) { oldValue, newValue in
            guard !oldValue, newValue else { return }

            let now = Date()
            guard now.timeIntervalSince(lastAlignmentHapticDate) >= 2.5 else { return }
            lastAlignmentHapticDate = now

            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
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
