import SwiftUI

struct QuranReaderView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selectedSurahID: String = ""
    @State private var ayahs: [QuranAyah] = []
    @State private var fontSize: Double = 32
    @State private var isShowingTranslation = true
    @State private var isLoading = false

    private var selectedSurah: QuranSurah? {
        appState.quranSurahs.first(where: { $0.id == selectedSurahID })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                controlsCard

                contentCard
            }
            .padding()
        }
        .navigationTitle(appState.localized("settings_quran_open_reader"))
        .navigationBarTitleDisplayMode(.inline)
        .premiumScreenBackground()
        .task {
            await bootstrapIfNeeded()
        }
        .onChange(of: selectedSurahID) { _, _ in
            Task {
                await loadAyahs(forceRefresh: false)
            }
        }
    }

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(appState.localized("settings_quran_surah"))
                    .font(.headline)
                Spacer()

                Button {
                    Task {
                        await loadAyahs(forceRefresh: true)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            if appState.quranSurahs.isEmpty {
                Text(appState.localized("settings_quran_no_surah"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Picker(appState.localized("settings_quran_surah"), selection: $selectedSurahID) {
                    ForEach(appState.quranSurahs) { surah in
                        Text(surah.title).tag(surah.id)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text(appState.localized("settings_text_size"))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(fontSize))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Slider(value: $fontSize, in: 20...52, step: 1)
                .tint(PremiumPalette.navy)

            Toggle(isOn: $isShowingTranslation) {
                Label(appState.localized("settings_quran_translation_toggle"), systemImage: "text.book.closed")
            }
            .toggleStyle(.switch)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedSurah?.nameTr ?? appState.localized("settings_quran_open_reader"))
                        .font(.headline)
                    if let selectedSurah {
                        Text("\(selectedSurah.verseCount) ayet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isLoading {
                    ProgressView()
                }
            }

            if ayahs.isEmpty && !isLoading {
                Text(appState.localized("settings_quran_no_ayah"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(ayahs) { ayah in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(ayah.ayahNo)")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(PremiumPalette.gold.opacity(0.24)))
                                Spacer()
                            }

                            Text(ayah.text)
                                .font(appState.quranReaderFont(size: CGFloat(fontSize), fallbackDesign: .serif))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .lineSpacing(10)

                            if isShowingTranslation,
                               let translation = ayah.translation,
                               !translation.isEmpty {
                                Text(translation)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.68))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PremiumPalette.navy.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
    }

    private func bootstrapIfNeeded() async {
        if appState.quranSurahs.isEmpty {
            await appState.syncQuranCatalog()
        }

        if selectedSurahID.isEmpty {
            selectedSurahID = appState.quranSurahs.first?.id ?? "1"
        }

        await loadAyahs(forceRefresh: false)
    }

    private func loadAyahs(forceRefresh: Bool) async {
        guard !selectedSurahID.isEmpty else { return }

        isLoading = true
        let values = await appState.quranAyahs(for: selectedSurahID, forceRefresh: forceRefresh)
        ayahs = values
        isLoading = false
    }
}
