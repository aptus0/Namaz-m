import SwiftUI
import UIKit
import AVFoundation
import Combine

struct DailyContentScreenView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var selectedTab: HadithModuleTab = .daily
    @State private var isCopyAlertPresented = false
    @State private var activeReaderTarget: HadithReaderTarget?

    private var todaySelection: HadithDailySelection {
        appState.dailyHadithSelection()
    }

    private var todayContentType: DailyContentType {
        todaySelection.hadith.contentType
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HadithShowcaseHero(
                        selection: todaySelection,
                        syncState: appState.hadithSyncState,
                        source: appState.hadithSource,
                        contentType: todayContentType
                    )

                    Picker("Icerik", selection: $selectedTab) {
                        ForEach(HadithModuleTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedTab {
                    case .daily:
                        DailyHadithTabCard(
                            selection: todaySelection,
                            isFavorite: appState.isHadithFavorite(todaySelection.hadith),
                            textSize: appState.hadithTextSize,
                            isSimpleMode: appState.hadithReadingModeSimple,
                            contentType: todayContentType,
                            onCopy: {
                                UIPasteboard.general.string = todaySelection.hadith.shareText
                                isCopyAlertPresented = true
                            },
                            onToggleFavorite: {
                                appState.toggleHadithFavorite(todaySelection.hadith)
                            },
                            onOpenReader: {
                                openReader(bookID: todaySelection.book.id, hadithID: todaySelection.hadith.id)
                            }
                        )

                    case .books:
                        HadithBooksTabView { bookID, hadithID in
                            openReader(bookID: bookID, hadithID: hadithID)
                        }

                    case .favorites:
                        HadithFavoritesTabView { bookID, hadithID in
                            openReader(bookID: bookID, hadithID: hadithID)
                        }
                    }

                    if adManager.shouldShowBannerAds {
                        BannerAdView(adUnitID: AdMobConfig.bannerUnitID)
                            .frame(height: 60)
                            .premiumCardStyle()
                    }
                }
                .padding()
            }
            .navigationTitle("Icerik")
            .premiumScreenBackground()
            .alert("Icerik panoya kopyalandi.", isPresented: $isCopyAlertPresented) {
                Button("Tamam", role: .cancel) {}
            }
            .navigationDestination(item: $activeReaderTarget) { target in
                HadithReaderView(bookID: target.bookID, startHadithID: target.hadithID)
            }
            .onChange(of: selectedTab) { _, newValue in
                if newValue == .favorites {
                    adManager.showInterstitialIfEligible(for: .hadithCollection)
                }
            }
            .onChange(of: notificationManager.pendingHadithDeepLink) { _, deepLink in
                guard let deepLink else { return }
                selectedTab = .daily
                openReader(bookID: deepLink.bookID, hadithID: deepLink.hadithID)
                notificationManager.pendingHadithDeepLink = nil
            }
            .onChange(of: notificationManager.pendingHadithSave) { _, deepLink in
                guard let deepLink, let hadith = appState.hadithItem(id: deepLink.hadithID) else { return }
                appState.markHadithFavorite(hadith)
                notificationManager.pendingHadithSave = nil
            }
        }
    }

    private func openReader(bookID: String, hadithID: String?) {
        activeReaderTarget = HadithReaderTarget(bookID: bookID, hadithID: hadithID)
    }
}

private struct HadithShowcaseHero: View {
    let selection: HadithDailySelection
    let syncState: HadithSyncState
    let source: HadithSourceOption
    let contentType: DailyContentType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Icerik Kutuphanesi")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(selection.book.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(1)
                }

                Spacer()

                Text("Canli API")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.16)))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8) {
                Image(systemName: contentType.symbolName)
                Text(contentType.title)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white.opacity(0.18)))
            .foregroundStyle(.white.opacity(0.94))

            Text(selection.hadith.shortText)
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(3)

            Label(syncTitle, systemImage: syncIcon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.86))
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

    private var syncTitle: String {
        switch syncState {
        case .idle:
            return "Henuz esitleme yapilmadi"
        case .syncing:
            return "Icerikler esitleniyor"
        case .synced(let count, let date):
            return "\(count) icerik • \(date.formatted(.dateTime.hour().minute()))"
        case .failed:
            return "API erisimi yoksa onbellek ile devam ediliyor"
        }
    }

    private var syncIcon: String {
        switch syncState {
        case .idle:
            return "cloud"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.seal.fill"
        case .failed:
            return "externaldrive.badge.exclamationmark"
        }
    }
}

private struct DailyHadithTabCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let selection: HadithDailySelection
    let isFavorite: Bool
    let textSize: HadithTextSize
    let isSimpleMode: Bool
    let contentType: DailyContentType
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onOpenReader: () -> Void

    @StateObject private var speechController = HadithSpeechController()

    private var displayFont: Font {
        let base = textSize.pointSize + (isSimpleMode ? 3 : 0)
        return .system(size: base, weight: .regular, design: .rounded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gunun Icerigi")
                        .font(.title3.weight(.semibold))
                    Text(selection.date.formatted(.dateTime.day().month().year()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                ContentTypeBadge(text: contentType.title)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(selection.hadith.text)
                    .font(displayFont)
                    .lineSpacing(isSimpleMode ? 12 : 8)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("Kaynak: \(selection.hadith.source)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Koleksiyon: \(selection.book.title) • \(selection.section.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(cardSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                geometricPattern
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            )

            HStack(spacing: 10) {
                Button(action: onOpenReader) {
                    Label("Okuyucuda Ac", systemImage: "book.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(PremiumPalette.navy)

                actionMenu
            }
        }
        .premiumCardStyle()
        .onDisappear {
            speechController.stop()
        }
    }

    private var cardSurface: Color {
        if isSimpleMode {
            return colorScheme == .dark
                ? Color(red: 0.14, green: 0.15, blue: 0.18)
                : Color(red: 0.98, green: 0.97, blue: 0.94)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.accentColor.opacity(0.07)
    }

    private var geometricPattern: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                .frame(width: 220, height: 220)
                .offset(x: 110, y: -90)

            Circle()
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                .frame(width: 130, height: 130)
                .offset(x: -130, y: 60)
        }
        .allowsHitTesting(false)
    }

    private func toggleSpeech() {
        speechController.toggleSpeech(text: selection.hadith.text, languageCode: "tr-TR")
    }

    private var actionMenu: some View {
        Menu {
            ShareLink(item: selection.hadith.shareText) {
                Label("Paylas", systemImage: "square.and.arrow.up")
            }

            Button(action: onCopy) {
                Label("Kopyala", systemImage: "doc.on.doc")
            }

            Button(action: onToggleFavorite) {
                Label(isFavorite ? "Favoriden Cikar" : "Favori", systemImage: isFavorite ? "heart.fill" : "heart")
            }

            Button(action: toggleSpeech) {
                Label(speechController.isSpeaking ? "Okumayi Durdur" : "Sesli Dinle", systemImage: speechController.isSpeaking ? "stop.circle" : "speaker.wave.2")
            }
        } label: {
            Label("Islemler", systemImage: "ellipsis.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

@MainActor
private final class HadithSpeechController: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func toggleSpeech(text: String, languageCode: String) {
        if isSpeaking {
            stop()
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension HadithSpeechController: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}

private struct HadithBooksTabView: View {
    @EnvironmentObject private var appState: AppState
    let onOpenReader: (String, String?) -> Void

    var body: some View {
        let books = appState.hadithBooks

        if books.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Kitap verisi bulunamadi.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .premiumCardStyle()
        } else {
            LazyVStack(spacing: 12) {
                ForEach(books) { book in
                    let progress = appState.readingProgress(for: book.id)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Image(systemName: book.contentType.symbolName)
                                .font(.title2)
                                .foregroundStyle(PremiumPalette.gold)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(book.title)
                                    .font(.headline)

                                Text(book.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if appState.hadithDefaultBookID == book.id {
                                Text("Varsayilan")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(PremiumPalette.gold.opacity(0.22)))
                            }
                        }

                        if let progress {
                            Text("Devam: \(progress.contentType.title) \(progress.number)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 10) {
                            Button {
                                appState.hadithDefaultBookID = book.id
                            } label: {
                                Label("Kaynak Yap", systemImage: "checkmark.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                onOpenReader(book.id, progress?.id)
                            } label: {
                                Label(progress == nil ? "Kitabi Ac" : "Devam Et", systemImage: "arrow.right.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(PremiumPalette.navy)
                        }
                    }
                    .premiumCardStyle()
                }
            }
        }
    }
}

private struct HadithFavoritesTabView: View {
    @EnvironmentObject private var appState: AppState
    let onOpenReader: (String, String?) -> Void

    private var favorites: [HadithItem] {
        appState.favoriteHadiths
    }

    var body: some View {
        if favorites.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "heart.slash")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Henuz favori icerik yok.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .premiumCardStyle()
        } else {
            LazyVStack(spacing: 12) {
                ForEach(favorites) { hadith in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(appState.hadithBook(id: hadith.bookID)?.title ?? "Koleksiyon")
                                .font(.headline)
                            Spacer()
                            ContentTypeBadge(text: hadith.contentType.title)
                        }

                        Text(hadith.text)
                            .font(.body)
                            .lineLimit(4)
                            .foregroundStyle(.primary)

                        Text(hadith.source)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button {
                                onOpenReader(hadith.bookID, hadith.id)
                            } label: {
                                Label("Oku", systemImage: "book")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                appState.toggleHadithFavorite(hadith)
                            } label: {
                                Label("Kaldir", systemImage: "heart.slash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .premiumCardStyle()
                }
            }
        }
    }
}

private struct HadithReaderTarget: Identifiable, Hashable {
    let bookID: String
    let hadithID: String?

    var id: String {
        "\(bookID)-\(hadithID ?? "latest")"
    }
}
