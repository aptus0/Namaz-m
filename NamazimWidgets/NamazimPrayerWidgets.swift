import WidgetKit
import SwiftUI
import AppIntents

struct NamazimPrayerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Namazım Widget"
    static var description = IntentDescription("Bir sonraki vakit, günlük vakitler ve hadis görünümü.")
}

struct NamazimPrayerTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = PrayerWidgetEntry
    typealias Intent = NamazimPrayerWidgetIntent

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        PrayerWidgetEntry(date: Date(), payload: .placeholder)
    }

    func snapshot(for configuration: NamazimPrayerWidgetIntent, in context: Context) async -> PrayerWidgetEntry {
        PrayerWidgetEntry(date: Date(), payload: WidgetPayloadStore.loadPayload())
    }

    func timeline(for configuration: NamazimPrayerWidgetIntent, in context: Context) async -> Timeline<PrayerWidgetEntry> {
        let payload = WidgetPayloadStore.loadPayload()
        let now = Date()

        let refreshDates = payload.refreshDates
            .filter { $0 > now }
            .prefix(5)

        let timelineDates: [Date]
        if refreshDates.isEmpty {
            timelineDates = [now, payload.nextPrayerDate, now.addingTimeInterval(30 * 60)].sorted()
        } else {
            timelineDates = Array(refreshDates)
        }

        let entries = timelineDates.map { date in
            PrayerWidgetEntry(date: date, payload: payload)
        }

        return Timeline(entries: entries, policy: .after(timelineDates.last ?? now.addingTimeInterval(30 * 60)))
    }
}

struct NamazimPrayerWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "NamazimPrayerWidget",
            intent: NamazimPrayerWidgetIntent.self,
            provider: NamazimPrayerTimelineProvider()
        ) { entry in
            PrayerWidgetContentView(entry: entry)
        }
        .configurationDisplayName("Namazım Vakit")
        .description("Bir sonraki vakit, kalan süre ve bugünün vakitleri.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct NamazimHadithWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "NamazimHadithWidget",
            intent: NamazimPrayerWidgetIntent.self,
            provider: NamazimPrayerTimelineProvider()
        ) { entry in
            HadithWidgetContentView(entry: entry)
        }
        .configurationDisplayName("Namazım Günün Hadisi")
        .description("Kısa hadis kartı ve kaynak bilgisi.")
        .supportedFamilies([
            .systemSmall,
            .accessoryRectangular
        ])
    }
}

private struct PrayerWidgetContentView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    let entry: PrayerWidgetEntry

    private var theme: WidgetTheme {
        WidgetTheme.resolve(
            themePack: entry.payload.premiumThemePack,
            accentOption: entry.payload.accentOption,
            colorScheme: colorScheme
        )
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            smallView
        }
    }

    private var smallView: some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.payload.cityName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                Text(entry.payload.prayerName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Text(entry.payload.nextPrayerDate, style: .timer)
                    .font(.title3.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
                Text(entry.payload.nextPrayerDate, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            background
        }
    }

    private var mediumView: some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(entry.payload.cityName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text("Sonraki: \(entry.payload.prayerName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                }

                HStack(spacing: 14) {
                    ForEach(Array(entry.payload.dayEntries.prefix(6)), id: \.self) { item in
                        VStack(spacing: 4) {
                            Text(item.prayerName.prefix(3))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.textSecondary)
                            Text(item.prayerDate, format: .dateTime.hour().minute())
                                .font(.caption.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                HStack {
                    Text(entry.payload.nextPrayerDate, style: .timer)
                        .font(.headline.weight(.heavy))
                        .monospacedDigit()
                        .foregroundStyle(theme.accent)
                    Spacer()
                    Text(entry.payload.nextPrayerDate, format: .dateTime.hour().minute())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            background
        }
    }

    private var circularView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.backgroundTop, theme.backgroundBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 2) {
                Text(entry.payload.prayerName.prefix(1))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.textSecondary)
                Text(entry.payload.nextPrayerDate, style: .timer)
                    .font(.caption2.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
            }
            .padding(6)
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bir sonraki vakit")
                .font(.caption2)
                .foregroundStyle(theme.textSecondary)
            Text("\(entry.payload.prayerName) • \(entry.payload.nextPrayerDate.formatted(.dateTime.hour().minute()))")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(entry.payload.nextPrayerDate, style: .timer)
                .font(.headline.weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(theme.accent)
        }
    }

    private var inlineView: some View {
        HStack(spacing: 4) {
            Text(entry.payload.prayerName)
            Text(entry.payload.nextPrayerDate, format: .dateTime.hour().minute())
            Text("•")
            Text(entry.payload.nextPrayerDate, style: .timer)
                .monospacedDigit()
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(
                LinearGradient(
                    colors: [theme.backgroundTop, theme.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Circle()
                    .fill(theme.gold.opacity(0.16))
                    .frame(width: 130, height: 130)
                    .offset(x: 60, y: -60)
                    .blur(radius: 10)
            )
    }
}

private struct HadithWidgetContentView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    let entry: PrayerWidgetEntry

    private var theme: WidgetTheme {
        WidgetTheme.resolve(
            themePack: entry.payload.premiumThemePack,
            accentOption: entry.payload.accentOption,
            colorScheme: colorScheme
        )
    }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Text("Günün Hadisi")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                Text(entry.payload.hadithSnippet)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                Text(entry.payload.hadithSource)
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
            }
        default:
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.backgroundTop, theme.backgroundBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(alignment: .leading, spacing: 6) {
                    Text("Günün Hadisi")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                    Text(entry.payload.hadithSnippet)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(4)
                    Text(entry.payload.hadithSource)
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }
                .padding(12)
            }
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [theme.backgroundTop, theme.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
