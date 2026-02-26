import SwiftUI

struct AlarmRingView: View {
    @EnvironmentObject private var appState: AppState

    let event: AlarmEvent
    let onSnooze: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.20),
                    Color(red: 0.12, green: 0.20, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "alarm.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Color(red: 0.88, green: 0.68, blue: 0.20))

                Text("\(event.prayer.localizedTitle(language: appState.language)) Vakti")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(event.fireDate, format: .dateTime.hour().minute())")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .monospacedDigit()

                Text("Alarm modu aktif. Erteleyebilir veya kapatabilirsiniz.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        onSnooze()
                    } label: {
                        Label("Ertele 5 dk", systemImage: "zzz")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.88, green: 0.68, blue: 0.20))

                    Button {
                        onDismiss()
                    } label: {
                        Label("Kapat", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}
