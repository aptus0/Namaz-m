import SwiftUI

enum PremiumPalette {
    static let navy = Color(red: 0.07, green: 0.17, blue: 0.38)
    static let gold = Color(red: 0.86, green: 0.68, blue: 0.24)

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

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? PremiumPalette.darkSurface : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(PremiumPalette.navy.opacity(colorScheme == .dark ? 0.28 : 0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.07), radius: 10, x: 0, y: 4)
    }
}

struct PremiumScreenBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.07, green: 0.08, blue: 0.12), Color(red: 0.10, green: 0.12, blue: 0.18)]
                    : [PremiumPalette.lightSurface, Color(red: 0.91, green: 0.93, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
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
