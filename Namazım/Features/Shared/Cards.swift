import SwiftUI

struct NextPrayerCard: View {
    let prayerName: String
    let countdownText: String
    let progress: Double

    var body: some View {
        VStack(spacing: 14) {
            Text("Bir Sonraki Vakit")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text("\(prayerName)'a")
                        .font(.headline)
                    Text(countdownText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 220, height: 220)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
