import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var locationManager: LocationManager

    @State private var isShowingSplash = true

    var body: some View {
        Group {
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingFlowView()
                    .transition(.opacity)
            } else {
                RootTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isShowingSplash)
        .animation(.easeInOut(duration: 0.25), value: appState.hasCompletedOnboarding)
            .tint(appState.accent.color)
            .preferredColorScheme(appState.theme.colorScheme)
            .fullScreenCover(item: $notificationManager.activeAlarm) { alarm in
                AlarmRingView(
                    event: alarm,
                    onSnooze: { notificationManager.snoozeActiveAlarm() },
                    onDismiss: { notificationManager.dismissAlarm() }
                )
            }
            .task {
                if isShowingSplash {
                    try? await Task.sleep(for: .milliseconds(900))
                    isShowingSplash = false
                }
            }
            .onChange(of: locationManager.resolvedCity) { _, city in
                appState.applyDetectedCity(city)
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(NotificationManager())
        .environmentObject(LocationManager())
}
