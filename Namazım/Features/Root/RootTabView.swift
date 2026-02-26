import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            PrayerTimesView()
                .tabItem {
                    Label(appState.localized("tab_prayers"), systemImage: "clock.fill")
                }

            CalendarScreenView()
                .tabItem {
                    Label(appState.localized("tab_calendar"), systemImage: "calendar")
                }

            DailyContentScreenView()
                .tabItem {
                    Label(appState.localized("tab_hadith"), systemImage: "book.fill")
                }

            WorldCitiesView()
                .tabItem {
                    Label(appState.localized("tab_world"), systemImage: "globe.europe.africa.fill")
                }

            SettingsScreenView()
                .tabItem {
                    Label(appState.localized("tab_settings"), systemImage: "gearshape.fill")
                }
        }
    }
}
