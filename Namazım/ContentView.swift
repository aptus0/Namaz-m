import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        RootTabView()
            .tint(appState.accent.color)
            .preferredColorScheme(appState.theme.colorScheme)
            .fullScreenCover(item: $notificationManager.activeAlarm) { alarm in
                AlarmRingView(
                    event: alarm,
                    onSnooze: { notificationManager.snoozeActiveAlarm() },
                    onDismiss: { notificationManager.dismissAlarm() }
                )
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(NotificationManager())
}
