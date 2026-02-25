import SwiftUI

struct CityPickerSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    let onCitySelected: ((String) -> Void)?

    init(onCitySelected: ((String) -> Void)? = nil) {
        self.onCitySelected = onCitySelected
    }

    private var filteredCities: [String] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return appState.cities
        }
        return appState.cities.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredCities, id: \.self) { city in
                Button {
                    appState.selectedCity = city
                    onCitySelected?(city)
                    dismiss()
                } label: {
                    HStack {
                        Text(city)
                            .foregroundStyle(.primary)
                        Spacer()
                        if city == appState.selectedCity {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Sehir ara")
            .navigationTitle("Il Sec")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
