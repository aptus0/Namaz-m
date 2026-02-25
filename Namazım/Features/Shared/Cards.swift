import SwiftUI

struct NextPrayerCard: View {
    let prayerName: String
    let countdownText: String
    let progress: Double

    var body: some View {
        VStack(spacing: 14) {
            Text("Bir Sonraki Vakit")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.24), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        PremiumPalette.gold,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text("\(prayerName)'a")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(countdownText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 220, height: 220)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(PremiumPalette.heroGradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 5)
    }
}

struct PrayerTimeRowCard: View {
    let entry: PrayerEntry
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.prayer.symbolName)
                .font(.headline)
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.prayer.title)
                    .font(.headline)
                if isActive {
                    Text("Yaklasiyor")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.88, green: 0.68, blue: 0.20))
                }
            }

            Spacer()

            Text(entry.date, format: .dateTime.hour().minute())
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .padding()
        .premiumCardStyle()
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1.5)
        }
    }
}

struct ContentTypeBadge: View {
    let type: DailyContentType

    var body: some View {
        Text(type.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
            )
    }
}
