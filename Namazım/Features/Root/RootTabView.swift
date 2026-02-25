import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            PrayerTimesView()
                .tabItem {
                    Label("Vakitler", systemImage: "clock.fill")
                }

            CalendarScreenView()
                .tabItem {
                    Label("Takvim", systemImage: "calendar")
                }

            DailyContentScreenView()
                .tabItem {
                    Label("Icerik", systemImage: "book.fill")
                }

            SettingsScreenView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape.fill")
                }
        }
    }
}
