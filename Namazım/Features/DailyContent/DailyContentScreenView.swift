import SwiftUI
import UIKit

struct DailyContentScreenView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var adManager: AdManager

    @State private var selectedTab: DailyContentTab = .today
    @State private var isCopyAlertPresented = false

    private var selectedContent: DailyContent {
        DailyContentRepository.byTab[selectedTab] ?? DailyContentRepository.byTab[.today]!
    }

    private var allContents: [DailyContent] {
        DailyContentTab.allCases.compactMap { DailyContentRepository.byTab[$0] }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("Gun", selection: $selectedTab) {
                        ForEach(DailyContentTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(selectedContent.title)
                                .font(.title3.weight(.semibold))
                            Spacer()
                            ContentTypeBadge(type: selectedContent.type)
                        }

                        Text(selectedContent.text)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Kaynak: \(selectedContent.source)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()

                    VStack(spacing: 10) {
                        ShareLink(item: selectedContent.shareText) {
                            Label("Paylas", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            UIPasteboard.general.string = selectedContent.shareText
                            isCopyAlertPresented = true
                        } label: {
                            Label("Kopyala", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            appState.toggleFavorite(selectedContent)
                        } label: {
                            Label(
                                appState.isFavorite(selectedContent) ? "Favoriden Cikar" : "Favoriye Ekle",
                                systemImage: appState.isFavorite(selectedContent) ? "heart.slash" : "heart"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    NavigationLink {
                        FavoritesView(allContents: allContents)
                    } label: {
                        Label("Favorileri Gor", systemImage: "bookmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if adManager.shouldShowBannerAds {
                        BannerAdView(adUnitID: AdMobConfig.bannerUnitID)
                            .frame(height: 60)
                            .premiumCardStyle()
                    }
                }
                .padding()
            }
            .navigationTitle("Gunun Icerigi")
            .premiumScreenBackground()
            .alert("Icerik panoya kopyalandi.", isPresented: $isCopyAlertPresented) {
                Button("Tamam", role: .cancel) {}
            }
        }
    }
}

private struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var adManager: AdManager
    let allContents: [DailyContent]

    private var favorites: [DailyContent] {
        allContents.filter { appState.isFavorite($0) }
    }

    var body: some View {
        List {
            if favorites.isEmpty {
                Text("Henuz favori icerik yok.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(favorites) { content in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(content.title)
                                .font(.headline)
                            Spacer()
                            ContentTypeBadge(type: content.type)
                        }

                        Text(content.text)
                            .lineLimit(3)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Favoriler")
        .onAppear {
            adManager.showInterstitialIfEligible(for: .hadithCollection)
        }
    }
}
