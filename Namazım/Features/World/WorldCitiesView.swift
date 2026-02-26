import SwiftUI
import Combine

struct WorldCitiesView: View {
    @EnvironmentObject private var appState: AppState

    @State private var now = Date()
    @State private var searchText = ""
    @State private var isPickerPresented = false

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var snapshots: [WorldCityPrayerSnapshot] {
        appState.worldPrayerSnapshots(now: now)
    }

    var body: some View {
        NavigationStack {
            List {
                if snapshots.isEmpty {
                    Text(appState.localized("world_empty"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshots) { snapshot in
                        WorldCitySnapshotCard(snapshot: snapshot)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    appState.removeWorldCity(snapshot.city)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .navigationTitle(appState.localized("screen_world"))
            .premiumScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPickerPresented = true
                    } label: {
                        Label(appState.localized("world_add_city"), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                WorldCityPickerSheet(searchText: searchText)
                    .environmentObject(appState)
            }
        }
        .onReceive(timer) { now = $0 }
    }
}

private struct WorldCitySnapshotCard: View {
    @EnvironmentObject private var appState: AppState

    let snapshot: WorldCityPrayerSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(snapshot.city.name)
                    .font(.headline)

                Text(snapshot.city.countryCode)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(PremiumPalette.gold.opacity(0.18)))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(appState.localized("world_local_time"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(snapshot.localTime)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.localized("world_next_prayer"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.nextPrayerName) • \(snapshot.nextPrayerTime)")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(appState.localized("world_remaining"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(snapshot.remaining)
                        .font(.headline.monospacedDigit())
                }
            }

            Text("\(appState.localized("world_timezone")): \(snapshot.timeZoneLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .premiumCardStyle()
    }
}

private struct WorldCityPickerSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State var searchText: String

    private var filteredCities: [WorldCity] {
        WorldCityCatalog.search(searchText, excluding: Set(appState.worldCityIDs))
    }

    var body: some View {
        NavigationStack {
            List(filteredCities) { city in
                Button {
                    appState.addWorldCity(city)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .foregroundStyle(.primary)
                            Text("\(city.countryCode) · \(city.timeZoneID)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(PremiumPalette.navy)
                    }
                }
            }
            .searchable(text: $searchText, prompt: appState.localized("world_search_placeholder"))
            .navigationTitle(appState.localized("world_add_city"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
