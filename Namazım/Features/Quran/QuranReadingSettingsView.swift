import SwiftUI
import UIKit

struct QuranReadingSettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var previewTextSize: Double = 31

    private let previewAyah = "بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard

                configCard

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(appState.localized("settings_quran_fonts"))
                            .font(.headline)

                        Spacer()

                        Button {
                            Task {
                                await appState.syncQuranFonts()
                            }
                        } label: {
                            Label(appState.localized("settings_sync_quran_fonts"), systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .tint(PremiumPalette.navy)
                    }

                    Text(fontSyncStateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if appState.quranFonts.isEmpty {
                        Text(appState.localized("settings_quran_fonts_empty"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(appState.quranFonts) { font in
                                fontRow(font)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .premiumCardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(appState.localized("settings_quran_preview"))
                            .font(.headline)
                        Spacer()
                        NavigationLink {
                            QuranReaderView()
                                .environmentObject(appState)
                        } label: {
                            Label(appState.localized("settings_quran_open_reader"), systemImage: "book.pages")
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Text(appState.localized("settings_text_size"))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(Int(previewTextSize))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $previewTextSize, in: 22...48, step: 1)
                        .tint(PremiumPalette.navy)

                    Text(previewAyah)
                        .font(appState.quranReaderFont(size: CGFloat(previewTextSize), fallbackDesign: .serif))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .lineSpacing(10)

                    if let selected = appState.selectedQuranFont {
                        Text("\(appState.localized("settings_quran_selected_font")): \(selected.normalizedDisplayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .premiumCardStyle()
            }
            .padding()
        }
        .navigationTitle(appState.localized("settings_quran_reading"))
        .navigationBarTitleDisplayMode(.inline)
        .premiumScreenBackground()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appState.localized("settings_quran_reading"))
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(appState.localized("settings_quran_subtitle"))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))

            HStack(spacing: 10) {
                Button {
                    Task {
                        await appState.syncQuranCatalog()
                    }
                } label: {
                    Label(appState.localized("settings_quran_sync_catalog"), systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(PremiumPalette.gold)

                Text(catalogSyncStateText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            PremiumPalette.navy.opacity(0.94),
                            PremiumPalette.navy.opacity(0.72),
                            PremiumPalette.gold.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: PremiumPalette.navy.opacity(0.25), radius: 14, x: 0, y: 7)
    }

    private var configCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(appState.localized("settings_quran_api_status"), systemImage: appState.quranAPIConfigured ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(appState.quranAPIConfigured ? .green : .orange)

            Text(appState.quranAPIConfigured
                 ? appState.localized("settings_quran_api_ready")
                 : appState.localized("settings_quran_api_missing"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }

    @ViewBuilder
    private func fontRow(_ font: QuranFont) -> some View {
        let state = appState.quranFontInstallState(for: font)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(font.normalizedDisplayName)
                        .font(.headline)

                    if let style = font.style, !style.isEmpty {
                        Text(style)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                statusBadge(for: state)
            }

            Text(previewAyah)
                .font(previewFont(for: font))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(8)

            HStack(spacing: 10) {
                if case .downloading = state {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button {
                        Task {
                            await handlePrimaryAction(for: font, state: state)
                        }
                    } label: {
                        Label(primaryActionTitle(for: font, state: state), systemImage: primaryActionSymbol(for: font, state: state))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(primaryActionTint(for: font, state: state))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PremiumPalette.navy.opacity(0.12), lineWidth: 1)
        )
    }

    private func handlePrimaryAction(for font: QuranFont, state: QuranFontInstallState) async {
        switch state {
        case .notDownloaded:
            await appState.installQuranFont(font)
        case .downloaded:
            appState.selectQuranFont(font)
        case .failed:
            await appState.installQuranFont(font)
        case .downloading:
            break
        }
    }

    private func previewFont(for font: QuranFont) -> Font {
        guard font.isDownloaded,
              let postScriptName = font.postScriptName,
              !postScriptName.isEmpty,
              UIFont(name: postScriptName, size: 24) != nil else {
            return .system(size: 24, weight: .regular, design: .serif)
        }

        return .custom(postScriptName, size: 24)
    }

    @ViewBuilder
    private func statusBadge(for state: QuranFontInstallState) -> some View {
        switch state {
        case .notDownloaded:
            badge(appState.localized("settings_quran_status_not_downloaded"), color: PremiumPalette.navy)
        case .downloading:
            badge(appState.localized("settings_quran_status_downloading"), color: .orange)
        case .downloaded:
            badge(appState.localized("settings_quran_status_downloaded"), color: .green)
        case .failed:
            badge(appState.localized("settings_quran_status_failed"), color: .red)
        }
    }

    private func badge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.14)))
    }

    private func primaryActionTitle(for font: QuranFont, state: QuranFontInstallState) -> String {
        switch state {
        case .notDownloaded:
            return appState.localized("settings_quran_download")
        case .downloading:
            return appState.localized("settings_quran_status_downloading")
        case .downloaded:
            return appState.selectedQuranFontID == font.id
                ? appState.localized("settings_quran_selected")
                : appState.localized("settings_quran_select")
        case .failed:
            return appState.localized("settings_quran_retry")
        }
    }

    private func primaryActionSymbol(for font: QuranFont, state: QuranFontInstallState) -> String {
        switch state {
        case .notDownloaded:
            return "arrow.down.circle"
        case .downloading:
            return "hourglass"
        case .downloaded:
            return appState.selectedQuranFontID == font.id ? "checkmark.seal.fill" : "checkmark.circle"
        case .failed:
            return "arrow.clockwise"
        }
    }

    private func primaryActionTint(for font: QuranFont, state: QuranFontInstallState) -> Color {
        switch state {
        case .notDownloaded:
            return PremiumPalette.navy
        case .downloading:
            return .orange
        case .downloaded:
            return appState.selectedQuranFontID == font.id ? .green : PremiumPalette.gold
        case .failed:
            return .red
        }
    }

    private var fontSyncStateText: String {
        switch appState.quranFontSyncState {
        case .idle:
            return appState.localized("settings_sync_idle")
        case .syncing:
            return appState.localized("settings_syncing")
        case .synced(let count, let date):
            return appState.localized("settings_quran_fonts_synced_count", count, date.formatted(.dateTime.hour().minute()))
        case .failed(let message):
            return appState.localized("settings_sync_failed", message)
        }
    }

    private var catalogSyncStateText: String {
        switch appState.quranCatalogSyncState {
        case .idle:
            return appState.localized("settings_sync_idle")
        case .syncing:
            return appState.localized("settings_syncing")
        case .synced(let count, let date):
            return appState.localized("settings_quran_catalog_synced_count", count, date.formatted(.dateTime.hour().minute()))
        case .failed(let message):
            return appState.localized("settings_sync_failed", message)
        }
    }
}
