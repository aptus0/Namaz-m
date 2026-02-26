import SwiftUI

struct AppIconSettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var isApplying = false
    @State private var selectedChoice: AppIconChoice = .primary
    @State private var errorMessage: String?

    private var iconSupported: Bool {
        AppIconManager.isSupported
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Uygulama İkonu")
                        .font(.title3.weight(.bold))

                    Text("4-6 alternatif ikon arasından seçim yapın. Seçim anında uygulanır.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if !iconSupported {
                        Text("Bu cihaz alternate app icon özelliğini desteklemiyor.")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .premiumCardStyle()

                ForEach(AppIconChoice.allCases) { choice in
                    Button {
                        apply(choice)
                    } label: {
                        HStack(spacing: 12) {
                            iconPreview(for: choice)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(choice.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(choice.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            if selectedChoice == choice {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.65))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selectedChoice == choice ? appState.accent.color.opacity(0.52) : Color.secondary.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!iconSupported || isApplying)
                }
            }
            .padding()
        }
        .navigationTitle("Uygulama İkonu")
        .premiumScreenBackground()
        .overlay(alignment: .top) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.90)))
                    .foregroundStyle(.white)
                    .padding(.top, 12)
            }
        }
        .onAppear {
            selectedChoice = appState.selectedAppIconChoice
        }
    }

    @ViewBuilder
    private func iconPreview(for choice: AppIconChoice) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(previewGradient(for: choice))
            .frame(width: 52, height: 52)
            .overlay(
                Image(systemName: previewSymbol(for: choice))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            )
    }

    private func previewGradient(for choice: AppIconChoice) -> LinearGradient {
        switch choice {
        case .primary, .crescentMinaret:
            return LinearGradient(colors: [Color(red: 0.07, green: 0.18, blue: 0.38), Color(red: 0.12, green: 0.31, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .modernClock:
            return LinearGradient(colors: [Color(red: 0.18, green: 0.22, blue: 0.35), Color(red: 0.28, green: 0.55, blue: 0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .monogramN:
            return LinearGradient(colors: [Color(red: 0.14, green: 0.15, blue: 0.20), Color(red: 0.08, green: 0.09, blue: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ramadanGlow:
            return LinearGradient(colors: [Color(red: 0.78, green: 0.58, blue: 0.20), Color(red: 0.95, green: 0.78, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .emeraldMark:
            return LinearGradient(colors: [Color(red: 0.08, green: 0.42, blue: 0.33), Color(red: 0.20, green: 0.64, blue: 0.50)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func previewSymbol(for choice: AppIconChoice) -> String {
        switch choice {
        case .primary, .crescentMinaret, .ramadanGlow, .emeraldMark:
            return "moon.stars.fill"
        case .modernClock:
            return "clock.fill"
        case .monogramN:
            return "textformat.abc"
        }
    }

    private func apply(_ choice: AppIconChoice) {
        guard iconSupported else { return }

        isApplying = true
        errorMessage = nil

        Task {
            do {
                try await AppIconManager.apply(choice: choice)
                appState.selectedAppIconChoice = choice
                selectedChoice = choice
            } catch {
                errorMessage = error.localizedDescription
            }

            isApplying = false

            if errorMessage != nil {
                try? await Task.sleep(for: .seconds(3))
                errorMessage = nil
            }
        }
    }
}
