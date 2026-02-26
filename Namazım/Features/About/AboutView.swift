import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var appState: AppState

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.3"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section("Uygulama") {
                LabeledContent("Surum", value: appVersionText)
                LabeledContent("Veri Kaynagi", value: "Content Pack + Cihaz ici hesaplama")
                LabeledContent("Canli ozellik", value: "Widget + Live Activity")
            }

            Section("Kaynaklar") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Namaz vakitleri: Sehir bazli solar hesaplama + cihaz saati.")
                    Text("Hadis katalogu: Content Pack (cihaz ici), secime gore uzak kaynak senkronu.")
                    Text("Kible: CoreLocation heading + buyuk cember (great-circle) hesaplamasi.")
                    Text("Gunun hadisi secimi: cihaz ici deterministic dongu.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Section("Hadis Durumu") {
                HStack {
                    Text("Senkron")
                    Spacer()
                    Text(syncStateTitle)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Kitap Sayisi")
                    Spacer()
                    Text("\(appState.hadithBooks.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Favoriler")
                    Spacer()
                    Text("\(appState.favoriteHadiths.count)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Gizlilik") {
                Text("Konum verisi sadece il secimi ve kibla hesaplamasi icin kullanilir. Bildirim ve hadis verileri cihaz ici cache ile calisir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Sorumluluk") {
                Text("Icerik kaynaklari farkli yayin politikalarina sahip olabilir. Kaynaklar duzenli olarak guncellenir, kritik dini konular icin resmi kaynaklarla dogrulayiniz.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Hakkinda")
    }

    private var syncStateTitle: String {
        switch appState.hadithSyncState {
        case .idle:
            return "Bekliyor"
        case .syncing:
            return "Senkronize ediliyor"
        case .synced(let count, let date):
            return "\(count) hadis • \(date.formatted(.dateTime.hour().minute()))"
        case .failed:
            return "Onbellek modunda"
        }
    }
}
