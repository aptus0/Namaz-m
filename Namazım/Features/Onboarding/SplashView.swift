import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.20),
                    Color(red: 0.10, green: 0.19, blue: 0.36),
                    Color(red: 0.15, green: 0.28, blue: 0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(PremiumPalette.gold.opacity(0.16))
                    .frame(width: 220, height: 220)
                    .blur(radius: 8)
                    .offset(x: isAnimating ? 28 : 46, y: -34)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isAnimating)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 190, height: 190)
                    .blur(radius: 10)
                    .offset(x: isAnimating ? -18 : -4, y: isAnimating ? 14 : 28)
                    .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: isAnimating)
            }
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .strokeBorder(.white.opacity(0.22), lineWidth: 1.5)
                        .frame(width: 120, height: 120)

                    Circle()
                        .strokeBorder(PremiumPalette.gold.opacity(0.70), lineWidth: 3.5)
                        .frame(width: 98, height: 98)
                        .scaleEffect(isAnimating ? 1.04 : 0.96)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(PremiumPalette.gold)
                }

                Text(appState.localized("app_name"))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Vakit, hadis ve kıble takibi")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.86))

                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Canlı ve hızlı")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.80))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
