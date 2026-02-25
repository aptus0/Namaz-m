import Foundation

enum DailyContentType: String {
    case hadis = "Hadis"
    case ayet = "Ayet"
    case dua = "Dua"
}

struct DailyContent: Identifiable, Equatable {
    let id: String
    let title: String
    let text: String
    let source: String
    let type: DailyContentType

    var shareText: String {
        "\(title)\n\n\(text)\n\nKaynak: \(source)"
    }
}

enum DailyContentTab: String, CaseIterable, Identifiable {
    case yesterday = "Dun"
    case today = "Bugun"
    case tomorrow = "Yarin"

    var id: Self { self }
}

enum DailyContentRepository {
    static let byTab: [DailyContentTab: DailyContent] = [
        .yesterday: DailyContent(
            id: "content-yesterday",
            title: "Gunun Duasi",
            text: "Allahim kalbimize huzur, evlerimize bereket, omrumuze hayir nasip eyle.",
            source: "Dua Mecmuasi",
            type: .dua
        ),
        .today: DailyContent(
            id: "content-today",
            title: "Gunun Hadisi",
            text: "Kolaylastiriniz, zorlastirmayiniz; mujdeleyiniz, nefret ettirmeyiniz.",
            source: "Buhari, Ilim",
            type: .hadis
        ),
        .tomorrow: DailyContent(
            id: "content-tomorrow",
            title: "Gunun Ayeti",
            text: "Suphesiz Allah sabredenlerle beraberdir.",
            source: "Bakara 2:153",
            type: .ayet
        )
    ]

    static var hadithSnippets: [String] {
        [
            "Kolaylastiriniz, zorlastirmayiniz.",
            "Mujdeleyiniz, nefret ettirmeyiniz.",
            "Ameller niyetlere goredir."
        ]
    }
}
