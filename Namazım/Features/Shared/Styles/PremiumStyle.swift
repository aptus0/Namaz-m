import SwiftUI

enum PremiumPalette {
    static let navy = Color(red: 0.07, green: 0.17, blue: 0.38)
    static let gold = Color(red: 0.86, green: 0.68, blue: 0.24)
    static let sky = Color(red: 0.40, green: 0.62, blue: 0.95)
    static let cloud = Color(red: 0.89, green: 0.93, blue: 0.99)

    static let lightSurface = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let darkSurface = Color(red: 0.11, green: 0.13, blue: 0.19)

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.08, green: 0.18, blue: 0.38), Color(red: 0.14, green: 0.29, blue: 0.54)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PremiumCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState

    func body(content: Content) -> some View {
        let palette = appState.themePalette(for: colorScheme)

        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.cardTop.opacity(0.98), palette.cardBottom.opacity(0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [palette.stroke.opacity(0.75), Color.white.opacity(colorScheme == .dark ? 0.08 : 0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: palette.glow.opacity(colorScheme == .dark ? 0.20 : 0.10), radius: 14, x: 0, y: 7)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.22 : 0.06), radius: 10, x: 0, y: 6)
            .animation(.easeInOut(duration: 0.28), value: appState.premiumThemePack)
    }
}

struct PremiumScreenBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState

    func body(content: Content) -> some View {
        let palette = appState.themePalette(for: colorScheme)

        content
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            palette.surfaceTop,
                            palette.surfaceBottom,
                            palette.surfaceTop.opacity(colorScheme == .dark ? 0.90 : 0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    palette.glow.opacity(colorScheme == .dark ? 0.42 : 0.26),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 300
                            )
                        )
                        .frame(width: 360, height: 360)
                        .offset(x: -120, y: -210)
                        .blur(radius: 18)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    palette.goldAccent.opacity(colorScheme == .dark ? 0.26 : 0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 260
                            )
                        )
                        .frame(width: 290, height: 290)
                        .offset(x: 150, y: -150)
                        .blur(radius: 14)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.03 : 0.10),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxHeight: 220)
                        .blendMode(.screen)
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.32), value: appState.premiumThemePack)
            )
    }
}

extension View {
    func premiumCardStyle() -> some View {
        modifier(PremiumCardModifier())
    }

    func premiumScreenBackground() -> some View {
        modifier(PremiumScreenBackgroundModifier())
    }
}
