import Foundation
import CoreGraphics

enum HadithModuleTab: String, CaseIterable, Identifiable {
    case daily = "Gunluk"
    case books = "Kitaplar"
    case favorites = "Favoriler"

    var id: Self { self }
}

enum HadithTextSize: String, CaseIterable, Identifiable {
    case small = "Kucuk"
    case medium = "Orta"
    case large = "Buyuk"

    var id: Self { self }

    var pointSize: CGFloat {
        switch self {
        case .small:
            return 17
        case .medium:
            return 21
        case .large:
            return 25
        }
    }
}

struct HadithBook: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let summary: String
    let coverSymbol: String
    let isFeatured: Bool
}

struct HadithSection: Identifiable, Equatable, Hashable {
    let id: String
    let bookID: String
    let title: String
    let order: Int
}

struct HadithItem: Identifiable, Equatable, Hashable {
    let id: String
    let bookID: String
    let sectionID: String
    let number: Int
    let text: String
    let shortText: String
    let source: String

    var shareText: String {
        "Hadis \(number)\n\n\(text)\n\nKaynak: \(source)"
    }
}

struct HadithDailySelection: Equatable {
    let date: Date
    let book: HadithBook
    let section: HadithSection
    let hadith: HadithItem
    let index: Int
}

enum HadithRepository {
    static let books: [HadithBook] = [
        HadithBook(
            id: "hadislerle-islam",
            title: "Hadislerle Islam",
            summary: "Diyanet referansli seckin hadis derlemesi.",
            coverSymbol: "book.closed.fill",
            isFeatured: true
        ),
        HadithBook(
            id: "yuz-hadis",
            title: "100 Hadis-i Serif",
            summary: "Gunluk hayata rehberlik eden temel hadisler.",
            coverSymbol: "book.pages.fill",
            isFeatured: true
        ),
        HadithBook(
            id: "ahlak-hadisleri",
            title: "Ahlak Hadisleri",
            summary: "Adap, merhamet ve guzel ahlaka dair secmeler.",
            coverSymbol: "heart.text.square.fill",
            isFeatured: false
        ),
        HadithBook(
            id: "namaz-hadisleri",
            title: "Namaz Hadisleri",
            summary: "Namaz suuru ve vakit hassasiyeti odakli hadisler.",
            coverSymbol: "clock.badge.checkmark.fill",
            isFeatured: true
        )
    ]

    static let sections: [HadithSection] = [
        HadithSection(id: "iman", bookID: "hadislerle-islam", title: "Iman ve Niyet", order: 1),
        HadithSection(id: "ibadet", bookID: "hadislerle-islam", title: "Ibadet Bilinci", order: 2),
        HadithSection(id: "genel", bookID: "yuz-hadis", title: "Genel Hayat", order: 1),
        HadithSection(id: "ahlak", bookID: "ahlak-hadisleri", title: "Ahlak ve Merhamet", order: 1),
        HadithSection(id: "vakit", bookID: "namaz-hadisleri", title: "Vakit ve Namaz", order: 1)
    ]

    static let hadiths: [HadithItem] = [
        HadithItem(
            id: "h1",
            bookID: "hadislerle-islam",
            sectionID: "iman",
            number: 1,
            text: "Ameller niyetlere goredir. Herkese niyet ettigi vardir.",
            shortText: "Ameller niyetlere goredir.",
            source: "Buhari, Bed'u'l-Vahy 1"
        ),
        HadithItem(
            id: "h2",
            bookID: "hadislerle-islam",
            sectionID: "iman",
            number: 2,
            text: "Allah sizin suretlerinize ve mallariniza degil, kalplerinize ve amellerinize bakar.",
            shortText: "Allah kalplere ve amellere bakar.",
            source: "Muslim, Birr 34"
        ),
        HadithItem(
            id: "h3",
            bookID: "hadislerle-islam",
            sectionID: "ibadet",
            number: 3,
            text: "Kolaylastiriniz, zorlastirmayiniz; mujdeleyiniz, nefret ettirmeyiniz.",
            shortText: "Kolaylastirin, zorlastirmayin.",
            source: "Buhari, Ilim 11"
        ),
        HadithItem(
            id: "h4",
            bookID: "hadislerle-islam",
            sectionID: "ibadet",
            number: 4,
            text: "Temizlik imanin yarisidir.",
            shortText: "Temizlik imanin yarisidir.",
            source: "Muslim, Taharet 1"
        ),
        HadithItem(
            id: "h5",
            bookID: "yuz-hadis",
            sectionID: "genel",
            number: 5,
            text: "Musluman, elinden ve dilinden insanlarin emin oldugu kimsedir.",
            shortText: "Musluman, elinden ve dilinden emin olunandir.",
            source: "Tirmizi, Iman 12"
        ),
        HadithItem(
            id: "h6",
            bookID: "yuz-hadis",
            sectionID: "genel",
            number: 6,
            text: "Kisiyi ilgilendirmeyen seyi terk etmesi, guzel muslumanligindandir.",
            shortText: "Luzumsuz olani terk etmek guzel muslumanliktandir.",
            source: "Tirmizi, Zuhd 11"
        ),
        HadithItem(
            id: "h7",
            bookID: "yuz-hadis",
            sectionID: "genel",
            number: 7,
            text: "Insanlarin en hayirlisi, insanlara en faydali olandir.",
            shortText: "En hayirli insan, en faydali olandir.",
            source: "Taberani, el-Mu'cemu'l-Evsat"
        ),
        HadithItem(
            id: "h8",
            bookID: "yuz-hadis",
            sectionID: "genel",
            number: 8,
            text: "Merhamet etmeyene merhamet olunmaz.",
            shortText: "Merhamet etmeyene merhamet olunmaz.",
            source: "Buhari, Tevhid 2"
        ),
        HadithItem(
            id: "h9",
            bookID: "ahlak-hadisleri",
            sectionID: "ahlak",
            number: 9,
            text: "Muminlerin iman bakimindan en olgunu, ahlaki en guzel olanidir.",
            shortText: "Imanca en olgun mumin, ahlaki guzel olandir.",
            source: "Ebu Davud, Sunnet 15"
        ),
        HadithItem(
            id: "h10",
            bookID: "ahlak-hadisleri",
            sectionID: "ahlak",
            number: 10,
            text: "Hediye veriniz ki birbirinize sevginiz artsin.",
            shortText: "Hediye vermek sevgiyi artirir.",
            source: "Buhari, Edebu'l-Mufred 594"
        ),
        HadithItem(
            id: "h11",
            bookID: "ahlak-hadisleri",
            sectionID: "ahlak",
            number: 11,
            text: "Guzel soz sadakadir.",
            shortText: "Guzel soz sadakadir.",
            source: "Buhari, Edeb 34"
        ),
        HadithItem(
            id: "h12",
            bookID: "ahlak-hadisleri",
            sectionID: "ahlak",
            number: 12,
            text: "Komusu aclikken tok yatan bizden degildir.",
            shortText: "Komusu aclikken tok yatan bizden degildir.",
            source: "Hakim, el-Mustedrek 7307"
        ),
        HadithItem(
            id: "h13",
            bookID: "namaz-hadisleri",
            sectionID: "vakit",
            number: 13,
            text: "Allah'a en sevimli amel, vaktinde kilinan namazdir.",
            shortText: "En sevimli amel, vaktinde kilinan namazdir.",
            source: "Buhari, Mevakit 5"
        ),
        HadithItem(
            id: "h14",
            bookID: "namaz-hadisleri",
            sectionID: "vakit",
            number: 14,
            text: "Namaz dinin diregidir.",
            shortText: "Namaz dinin diregidir.",
            source: "Tirmizi, Iman 8"
        ),
        HadithItem(
            id: "h15",
            bookID: "namaz-hadisleri",
            sectionID: "vakit",
            number: 15,
            text: "Cemaatle kilinan namaz, tek basina kilinan namazdan yirmi yedi derece ustundur.",
            shortText: "Cemaatle namaz yirmi yedi derece ustundur.",
            source: "Buhari, Ezan 30"
        ),
        HadithItem(
            id: "h16",
            bookID: "namaz-hadisleri",
            sectionID: "vakit",
            number: 16,
            text: "Kulun Rabbine en yakin oldugu an secde anidir; o halde duayi cogaltiniz.",
            shortText: "Kulun Rabbine en yakin oldugu an secdedir.",
            source: "Muslim, Salat 215"
        )
    ]

    static let hadithByID: [String: HadithItem] = Dictionary(uniqueKeysWithValues: hadiths.map { ($0.id, $0) })

    static var featuredBooks: [HadithBook] {
        books.filter(\.isFeatured)
    }

    static func book(id: String) -> HadithBook? {
        books.first(where: { $0.id == id })
    }

    static func sections(for bookID: String) -> [HadithSection] {
        sections
            .filter { $0.bookID == bookID }
            .sorted { $0.order < $1.order }
    }

    static func hadiths(for bookID: String) -> [HadithItem] {
        hadiths
            .filter { $0.bookID == bookID }
            .sorted { $0.number < $1.number }
    }

    static func section(bookID: String, sectionID: String) -> HadithSection? {
        sections.first { $0.bookID == bookID && $0.id == sectionID }
    }

    static func hadith(id: String) -> HadithItem? {
        hadithByID[id]
    }

    static func dailySelection(
        on date: Date,
        preferredBookID: String?,
        installSeed: Int
    ) -> HadithDailySelection {
        let pool = selectionPool(preferredBookID: preferredBookID)
        let safePool = pool.isEmpty ? hadiths : pool

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = abs(dayOfYear + installSeed) % safePool.count
        let hadith = safePool[index]
        let book = book(id: hadith.bookID) ?? books[0]
        let section = section(bookID: hadith.bookID, sectionID: hadith.sectionID) ?? sections[0]

        return HadithDailySelection(
            date: date,
            book: book,
            section: section,
            hadith: hadith,
            index: index
        )
    }

    static func shortSnippet(for hadith: HadithItem, maxLength: Int = 110) -> String {
        let trimmed = hadith.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else {
            return trimmed
        }

        let clipped = trimmed.prefix(max(1, maxLength - 1))
        return "\(clipped)…"
    }

    private static func selectionPool(preferredBookID: String?) -> [HadithItem] {
        if let preferredBookID, !preferredBookID.isEmpty {
            let preferred = hadiths(for: preferredBookID)
            if !preferred.isEmpty {
                return preferred
            }
        }

        let featuredIDs = Set(featuredBooks.map(\.id))
        let featuredPool = hadiths.filter { featuredIDs.contains($0.bookID) }.sorted { $0.number < $1.number }
        if !featuredPool.isEmpty {
            return featuredPool
        }

        return hadiths
    }
}
