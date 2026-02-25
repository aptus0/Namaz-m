import SwiftUI

struct AboutView: View {
    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.3"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section("Uygulama") {
                LabeledContent("Surum", value: appVersionText)
                LabeledContent("Veri Kaynagi", value: "Diyanet / Alternatif")
            }

            Section("Kaynaklar") {
                Text("Namaz vakitleri, hadis icerigi ve kibla hesaplama akislari iOS tarafinda premium deneyimle sunulur.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Gizlilik") {
                Text("Konum verisi sadece il secimi ve kibla hesaplamasi icin kullanilir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Hakkinda")
    }
}
