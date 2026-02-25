import SwiftUI
import UIKit

struct HadithReaderView: View {
    @EnvironmentObject private var appState: AppState

    let bookID: String
    let startHadithID: String?

    @State private var selectedIndex = 0
    @State private var didApplyStartIndex = false
    @State private var isReaderNightMode = false
    @State private var isCopyAlertPresented = false

    private var book: HadithBook {
        HadithRepository.book(id: bookID) ?? HadithRepository.books[0]
    }

    private var hadiths: [HadithItem] {
        HadithRepository.hadiths(for: bookID)
    }

    private var currentHadith: HadithItem? {
        guard hadiths.indices.contains(selectedIndex) else { return hadiths.first }
        return hadiths[selectedIndex]
    }

    private var currentSection: HadithSection? {
        guard let currentHadith else { return nil }
        return HadithRepository.section(bookID: currentHadith.bookID, sectionID: currentHadith.sectionID)
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)

                Text(currentSection?.title ?? "Hadis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .premiumCardStyle()

            if hadiths.isEmpty {
                Text("Bu kitapta hadis bulunamadi.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(hadiths.enumerated()), id: \.element.id) { index, hadith in
                        HadithReaderCard(
                            hadith: hadith,
                            section: HadithRepository.section(bookID: hadith.bookID, sectionID: hadith.sectionID),
                            textSize: appState.hadithTextSize,
                            isSimpleMode: appState.hadithReadingModeSimple,
                            isReaderNightMode: isReaderNightMode,
                            isFavorite: appState.isHadithFavorite(hadith),
                            onCopy: {
                                UIPasteboard.general.string = hadith.shareText
                                isCopyAlertPresented = true
                            },
                            onToggleFavorite: {
                                appState.toggleHadithFavorite(hadith)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(minHeight: 420)
                .onChange(of: selectedIndex) { _, _ in
                    persistReadingProgressIfPossible()
                }

                HStack(spacing: 10) {
                    Button {
                        selectedIndex = max(0, selectedIndex - 1)
                    } label: {
                        Label("Onceki", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedIndex == 0)

                    Button {
                        selectedIndex = min(hadiths.count - 1, selectedIndex + 1)
                    } label: {
                        Label("Sonraki", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedIndex >= hadiths.count - 1)
                }

                HStack(spacing: 10) {
                    Menu {
                        Picker("Yazi Boyutu", selection: $appState.hadithTextSize) {
                            ForEach(HadithTextSize.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                    } label: {
                        Label("Yazi Boyutu", systemImage: "textformat.size")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Toggle(isOn: $isReaderNightMode) {
                        Label("Gece Modu", systemImage: isReaderNightMode ? "moon.fill" : "moon")
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)

                    Toggle(isOn: $appState.hadithReadingModeSimple) {
                        Label("Sade", systemImage: appState.hadithReadingModeSimple ? "text.justify" : "text.alignleft")
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .navigationTitle("Okuyucu")
        .navigationBarTitleDisplayMode(.inline)
        .premiumScreenBackground()
        .alert("Hadis panoya kopyalandi.", isPresented: $isCopyAlertPresented) {
            Button("Tamam", role: .cancel) {}
        }
        .onAppear {
            applyStartIndexIfNeeded()
            persistReadingProgressIfPossible()
        }
    }

    private func applyStartIndexIfNeeded() {
        guard !didApplyStartIndex else { return }
        defer { didApplyStartIndex = true }

        if let startHadithID,
           let index = hadiths.firstIndex(where: { $0.id == startHadithID }) {
            selectedIndex = index
            return
        }

        if let progress = appState.readingProgress(for: bookID),
           let index = hadiths.firstIndex(where: { $0.id == progress.id }) {
            selectedIndex = index
        }
    }

    private func persistReadingProgressIfPossible() {
        guard let currentHadith else { return }
        appState.saveReadingProgress(bookID: bookID, hadithID: currentHadith.id)
    }
}

private struct HadithReaderCard: View {
    let hadith: HadithItem
    let section: HadithSection?
    let textSize: HadithTextSize
    let isSimpleMode: Bool
    let isReaderNightMode: Bool
    let isFavorite: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void

    private var displayFont: Font {
        let points = textSize.pointSize + (isSimpleMode ? 3 : 0)
        return .system(size: points, weight: .regular, design: .rounded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section?.title ?? "Hadis")
                        .font(.subheadline.weight(.semibold))
                    Text("Hadis #\(hadith.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                ContentTypeBadge(text: "Hadis")
            }

            ScrollView {
                Text(hadith.text)
                    .font(displayFont)
                    .lineSpacing(isSimpleMode ? 12 : 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
            }

            Text("Kaynak: \(hadith.source)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ShareLink(item: hadith.shareText) {
                    Label("Paylas", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onCopy) {
                    Label("Kopyala", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onToggleFavorite) {
                    Label(isFavorite ? "Favoriden Cikar" : "Favori", systemImage: isFavorite ? "heart.fill" : "heart")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isReaderNightMode ? 0.24 : 0.08), radius: 10, x: 0, y: 5)
    }

    private var surfaceColor: Color {
        if isReaderNightMode {
            return Color(red: 0.14, green: 0.15, blue: 0.18)
        }

        return Color(red: 0.98, green: 0.97, blue: 0.94)
    }
}
