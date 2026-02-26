import SwiftUI

struct NextPrayerCard: View {
    @EnvironmentObject private var appState: AppState

    let prayerName: String
    let nextDate: Date
    let previousDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let metrics = countdownMetrics(now: context.date)

            VStack(spacing: 14) {
                HStack {
                    Text(appState.localized("prayer_next"))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.92))
                    Spacer()
                    Text(prayerName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                }

                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.22), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: metrics.progress)
                        .stroke(
                            AngularGradient(
                                colors: [PremiumPalette.gold, Color.white, PremiumPalette.gold],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 8) {
                        Text(appState.localized("prayer_countdown_to", prayerName))
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.96))
                            .multilineTextAlignment(.center)

                        Text(metrics.countdown)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                }
                .frame(width: 220, height: 220)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(PremiumPalette.heroGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.20), radius: 14, x: 0, y: 6)
        }
    }

    private func countdownMetrics(now: Date) -> (countdown: String, progress: Double) {
        let countdown = countdownString(from: now, to: nextDate)
        let total = nextDate.timeIntervalSince(previousDate)
        guard total > 0 else {
            return (countdown, 0)
        }

        let elapsed = now.timeIntervalSince(previousDate)
        let progress = min(max(elapsed / total, 0), 1)
        return (countdown, progress)
    }
}

struct PrayerTimeRowCard: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    let entry: PrayerEntry
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.prayer.symbolName)
                .font(.headline)
                .foregroundStyle(isActive ? PremiumPalette.navy : .secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isActive ? PremiumPalette.gold.opacity(0.24) : Color.clear)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.prayer.localizedTitle(language: appState.language))
                    .font(.headline)
                if isActive {
                    Text(appState.localized("prayer_approaching"))
                        .font(.caption)
                        .foregroundStyle(PremiumPalette.gold)
                }
            }

            Spacer()

            Text(entry.date, format: .dateTime.hour().minute())
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isActive
                            ? activeBackgroundColors
                            : passiveBackgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isActive ? PremiumPalette.navy.opacity(0.30) : PremiumPalette.navy.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isActive ? 0.12 : 0.05), radius: isActive ? 10 : 7, x: 0, y: 4)
    }

    private var activeBackgroundColors: [Color] {
        if colorScheme == .dark {
            return [Color(red: 0.15, green: 0.18, blue: 0.26), PremiumPalette.gold.opacity(0.22)]
        }
        return [Color.white.opacity(0.96), PremiumPalette.gold.opacity(0.14)]
    }

    private var passiveBackgroundColors: [Color] {
        if colorScheme == .dark {
            return [Color(red: 0.11, green: 0.14, blue: 0.22), Color(red: 0.13, green: 0.16, blue: 0.24)]
        }
        return [Color.white.opacity(0.90), Color.white.opacity(0.78)]
    }
}

struct ContentTypeBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
            )
    }
}
