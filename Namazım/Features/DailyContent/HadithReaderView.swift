import SwiftUI
import UIKit

struct HadithReaderView: View {
    @EnvironmentObject private var appState: AppState

    let bookID: String
    let startHadithID: String?

    @AppStorage("hadith.reader.fontScale") private var fontScale: Double = 1.0
    @AppStorage("hadith.reader.lineSpacingScale") private var lineSpacingScale: Double = 1.0
    @State private var selectedIndex = 0
    @State private var didApplyStartIndex = false
    @State private var isReaderNightMode = false
    @State private var isImmersiveMode = false
    @State private var isCopyAlertPresented = false

    private var book: HadithBook {
        appState.hadithBook(id: bookID) ?? appState.hadithBooks.first ?? HadithCatalog.localDefault.books[0]
    }

    private var hadiths: [HadithItem] {
        appState.hadithItems(for: bookID)
    }

    private var currentHadith: HadithItem? {
        guard hadiths.indices.contains(selectedIndex) else { return hadiths.first }
        return hadiths[selectedIndex]
    }

    private var currentSection: HadithSection? {
        guard let currentHadith else { return nil }
        return appState.hadithSection(bookID: currentHadith.bookID, sectionID: currentHadith.sectionID)
    }

    var body: some View {
        VStack(spacing: isImmersiveMode ? 10 : 14) {
            if !isImmersiveMode {
                readerHeader
            }

            if hadiths.isEmpty {
                Text("Bu kitapta icerik bulunamadi.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCardStyle()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        if let currentHadith {
                            HadithReaderCard(
                                hadith: currentHadith,
                                section: currentSection,
                                textSize: appState.hadithTextSize,
                                isSimpleMode: appState.hadithReadingModeSimple,
                                isReaderNightMode: isReaderNightMode,
                                fontScale: fontScale,
                                lineSpacingScale: lineSpacingScale,
                                contentType: currentHadith.contentType
                            )
                            .id(currentHadith.id)
                            .padding(.bottom, 8)
                        }
                    }
                    .scrollIndicators(.visible)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: selectedIndex) { _, _ in
                        persistReadingProgressIfPossible()
                        if let id = currentHadith?.id {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }
                    }
                }

                if !isImmersiveMode {
                    readerNavigation
                }
            }
        }
        .padding()
        .navigationTitle("Okuyucu")
        .navigationBarTitleDisplayMode(.inline)
        .premiumScreenBackground()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !hadiths.isEmpty {
                    readerActionMenu
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isImmersiveMode.toggle()
                    }
                } label: {
                    Image(systemName: isImmersiveMode ? "rectangle.inset.filled.and.person.filled" : "viewfinder.circle")
                }
            }
        }
        .alert("Icerik panoya kopyalandi.", isPresented: $isCopyAlertPresented) {
            Button("Tamam", role: .cancel) {}
        }
        .onAppear {
            applyStartIndexIfNeeded()
            persistReadingProgressIfPossible()
        }
    }

    private var readerHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.headline)

                    Text(currentSection?.title ?? "Icerik")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let currentHadith {
                    ContentTypeBadge(text: currentHadith.contentType.title)
                }
            }

            if !hadiths.isEmpty {
                Text("\(selectedIndex + 1) / \(hadiths.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }

    private var readerNavigation: some View {
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
            .buttonStyle(.borderedProminent)
            .tint(PremiumPalette.navy)
            .disabled(selectedIndex >= hadiths.count - 1)
        }
    }

    private var readerActionMenu: some View {
        Menu {
            if let currentHadith {
                ShareLink(item: currentHadith.shareText) {
                    Label("Paylas", systemImage: "square.and.arrow.up")
                }

                Button {
                    UIPasteboard.general.string = currentHadith.shareText
                    isCopyAlertPresented = true
                } label: {
                    Label("Kopyala", systemImage: "doc.on.doc")
                }

                Button {
                    appState.toggleHadithFavorite(currentHadith)
                } label: {
                    Label(
                        appState.isHadithFavorite(currentHadith) ? "Favoriden Cikar" : "Favori",
                        systemImage: appState.isHadithFavorite(currentHadith) ? "heart.fill" : "heart"
                    )
                }
            }

            Divider()

            Picker("Yazi Boyutu", selection: $appState.hadithTextSize) {
                ForEach(HadithTextSize.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }

            Button {
                fontScale = min(1.7, fontScale + 0.05)
            } label: {
                Label("Yaziyi Buyut", systemImage: "plus.magnifyingglass")
            }

            Button {
                fontScale = max(0.85, fontScale - 0.05)
            } label: {
                Label("Yaziyi Kucult", systemImage: "minus.magnifyingglass")
            }

            Button {
                lineSpacingScale = min(1.9, lineSpacingScale + 0.05)
            } label: {
                Label("Satir Araligini Artir", systemImage: "increase.indent")
            }

            Button {
                lineSpacingScale = max(0.8, lineSpacingScale - 0.05)
            } label: {
                Label("Satir Araligini Azalt", systemImage: "decrease.indent")
            }

            Divider()

            Button {
                isReaderNightMode.toggle()
            } label: {
                Label(isReaderNightMode ? "Gece Modunu Kapat" : "Gece Modu", systemImage: isReaderNightMode ? "moon.fill" : "moon")
            }

            Button {
                appState.hadithReadingModeSimple.toggle()
            } label: {
                Label(
                    appState.hadithReadingModeSimple ? "Normal Mod" : "Sade Mod",
                    systemImage: appState.hadithReadingModeSimple ? "text.justify" : "text.alignleft"
                )
            }
        } label: {
            Image(systemName: "ellipsis.circle")
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
    let fontScale: Double
    let lineSpacingScale: Double
    let contentType: DailyContentType

    private var displayFont: Font {
        let basePoints = textSize.pointSize + (isSimpleMode ? 3 : 0)
        let points = basePoints * fontScale
        return .system(size: points, weight: .regular, design: .rounded)
    }

    private var computedLineSpacing: CGFloat {
        CGFloat((isSimpleMode ? 12 : 8) * lineSpacingScale)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section?.title ?? "Icerik")
                        .font(.subheadline.weight(.semibold))
                    Text("\(contentType.title) #\(hadith.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                ContentTypeBadge(text: contentType.title)
            }

            Text(hadith.text)
                .font(displayFont)
                .lineSpacing(computedLineSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            Text("Kaynak: \(hadith.source)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isReaderNightMode ? 0.24 : 0.08), radius: 10, x: 0, y: 5)
    }

    private var surfaceColor: Color {
        if isReaderNightMode {
            return Color(red: 0.14, green: 0.15, blue: 0.18)
        }

        return Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    private var borderColor: Color {
        isReaderNightMode ? Color.white.opacity(0.14) : Color.accentColor.opacity(0.18)
    }
}
