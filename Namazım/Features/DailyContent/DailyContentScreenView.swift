import SwiftUI
import UIKit
import AVFoundation

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("Hadis", selection: $selectedTab) {
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
            .navigationTitle("Hadis")
            .premiumScreenBackground()
            .alert("Hadis panoya kopyalandi.", isPresented: $isCopyAlertPresented) {
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
                guard let deepLink, let hadith = HadithRepository.hadith(id: deepLink.hadithID) else { return }
                appState.markHadithFavorite(hadith)
                notificationManager.pendingHadithSave = nil
            }
        }
    }

    private func openReader(bookID: String, hadithID: String?) {
        activeReaderTarget = HadithReaderTarget(bookID: bookID, hadithID: hadithID)
    }
}

private struct DailyHadithTabCard: View {
    let selection: HadithDailySelection
    let isFavorite: Bool
    let textSize: HadithTextSize
    let isSimpleMode: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onOpenReader: () -> Void

    @State private var isSpeaking = false
    private let speechSynthesizer = AVSpeechSynthesizer()

    private var displayFont: Font {
        let base = textSize.pointSize + (isSimpleMode ? 3 : 0)
        return .system(size: base, weight: .regular, design: .rounded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gunun Hadisi")
                        .font(.title3.weight(.semibold))
                    Text(selection.date.formatted(.dateTime.day().month().year()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                ContentTypeBadge(text: "Hadis")
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
                ShareLink(item: selection.hadith.shareText) {
                    Label("Paylas", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onCopy) {
                    Label("Kopyala", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Button(action: onToggleFavorite) {
                    Label(isFavorite ? "Favoriden Cikar" : "Favori", systemImage: isFavorite ? "heart.fill" : "heart")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isFavorite ? .pink : PremiumPalette.navy)

                Button {
                    toggleSpeech()
                } label: {
                    Label(isSpeaking ? "Dur" : "Dinle", systemImage: isSpeaking ? "stop.circle" : "speaker.wave.2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button(action: onOpenReader) {
                Label("Okuyucuda Ac", systemImage: "book")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .premiumCardStyle()
    }

    private var cardSurface: Color {
        isSimpleMode ? Color(white: 0.16) : Color.accentColor.opacity(0.07)
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
        if isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }

        let utterance = AVSpeechUtterance(string: selection.hadith.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        utterance.rate = 0.45
        speechSynthesizer.speak(utterance)
        isSpeaking = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if speechSynthesizer.isSpeaking {
                isSpeaking = true
            } else {
                isSpeaking = false
            }
        }
    }
}

private struct HadithBooksTabView: View {
    @EnvironmentObject private var appState: AppState
    let onOpenReader: (String, String?) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(HadithRepository.books) { book in
                let progress = appState.readingProgress(for: book.id)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Image(systemName: book.coverSymbol)
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
                        Text("Devam: Hadis \(progress.number)")
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

                Text("Henuz favori hadis yok.")
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
                            Text(HadithRepository.book(id: hadith.bookID)?.title ?? "Koleksiyon")
                                .font(.headline)
                            Spacer()
                            Text("#\(hadith.number)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
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
