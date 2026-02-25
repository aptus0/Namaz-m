import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            PremiumPalette.heroGradient
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "moon.stars.circle.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(PremiumPalette.gold)

                Text("Namazim")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Vakit, hadis ve kibla takibi")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.86))
            }
        }
    }
}
