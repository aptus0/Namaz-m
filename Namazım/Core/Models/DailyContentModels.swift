import Foundation
import CoreGraphics

enum DailyContentType: String, CaseIterable, Identifiable {
    case hadith
    case ayah
    case dua

    var id: Self { self }

    var title: String {
        switch self {
        case .hadith:
            return "Hadis"
        case .ayah:
            return "Ayet"
        case .dua:
            return "Dua"
        }
    }

    var symbolName: String {
        switch self {
        case .hadith:
            return "text.book.closed.fill"
        case .ayah:
            return "book.pages.fill"
        case .dua:
            return "hands.and.sparkles.fill"
        }
    }
}

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

    var contentType: DailyContentType {
        DailyContentType.resolve(bookID: id, title: title)
    }
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

    var contentType: DailyContentType {
        DailyContentType.resolve(bookID: bookID, title: bookID)
    }

    var shareText: String {
        "\(contentType.title) \(number)\n\n\(text)\n\nKaynak: \(source)"
    }
}

struct HadithDailySelection: Equatable {
    let date: Date
    let book: HadithBook
    let section: HadithSection
    let hadith: HadithItem
    let index: Int
}

extension DailyContentType {
    static func resolve(bookID: String, title: String) -> DailyContentType {
        let searchable = "\(bookID) \(title)"
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()

        if searchable.contains("dua") || searchable.contains("supplication") {
            return .dua
        }

        if searchable.contains("ayet")
            || searchable.contains("ayah")
            || searchable.contains("quran")
            || searchable.contains("kuran")
            || searchable.contains("kur'an") {
            return .ayah
        }

        return .hadith
    }
}

enum HadithRepository {
    nonisolated(unsafe) static let books: [HadithBook] = [
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

    nonisolated(unsafe) static let sections: [HadithSection] = [
        HadithSection(id: "iman", bookID: "hadislerle-islam", title: "Iman ve Niyet", order: 1),
        HadithSection(id: "ibadet", bookID: "hadislerle-islam", title: "Ibadet Bilinci", order: 2),
        HadithSection(id: "genel", bookID: "yuz-hadis", title: "Genel Hayat", order: 1),
        HadithSection(id: "ahlak", bookID: "ahlak-hadisleri", title: "Ahlak ve Merhamet", order: 1),
        HadithSection(id: "vakit", bookID: "namaz-hadisleri", title: "Vakit ve Namaz", order: 1)
    ]

    nonisolated(unsafe) static let hadiths: [HadithItem] = [
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

    nonisolated(unsafe) static let hadithByID: [String: HadithItem] = Dictionary(uniqueKeysWithValues: hadiths.map { ($0.id, $0) })

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

struct HadithCatalog {
    let books: [HadithBook]
    let sections: [HadithSection]
    let hadiths: [HadithItem]

    private let bookByID: [String: HadithBook]
    private let sectionByCompositeID: [String: HadithSection]
    private let hadithByID: [String: HadithItem]

    init(books: [HadithBook], sections: [HadithSection], hadiths: [HadithItem]) {
        self.books = books
        self.sections = sections
        self.hadiths = hadiths
        self.bookByID = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })
        self.sectionByCompositeID = Dictionary(uniqueKeysWithValues: sections.map { ("\($0.bookID)#\($0.id)", $0) })
        self.hadithByID = Dictionary(uniqueKeysWithValues: hadiths.map { ($0.id, $0) })
    }

    static let localDefault = HadithCatalog(
        books: HadithRepository.books,
        sections: HadithRepository.sections,
        hadiths: HadithRepository.hadiths
    )

    static func remote(records: [HadithRemoteRecord]) -> HadithCatalog? {
        guard !records.isEmpty else { return nil }

        struct BookAccumulator {
            var title: String
            var count: Int
        }

        struct SectionAccumulator {
            var bookID: String
            var title: String
            var count: Int
        }

        var bookAcc: [String: BookAccumulator] = [:]
        var sectionAcc: [String: SectionAccumulator] = [:]
        var hadithItems: [HadithItem] = []

        for record in records {
            let bookID = "remote-\(slug(record.bookTitle))"
            let sectionID = "section-\(slug(record.sectionTitle))"
            let compositeSectionID = "\(bookID)#\(sectionID)"

            if var existingBook = bookAcc[bookID] {
                existingBook.count += 1
                bookAcc[bookID] = existingBook
            } else {
                bookAcc[bookID] = BookAccumulator(title: cleaned(record.bookTitle), count: 1)
            }

            if var existingSection = sectionAcc[compositeSectionID] {
                existingSection.count += 1
                sectionAcc[compositeSectionID] = existingSection
            } else {
                sectionAcc[compositeSectionID] = SectionAccumulator(
                    bookID: bookID,
                    title: cleaned(record.sectionTitle),
                    count: 1
                )
            }

            let text = cleaned(record.text)
            let short = text.count <= 120 ? text : "\(text.prefix(119))…"

            hadithItems.append(
                HadithItem(
                    id: record.id,
                    bookID: bookID,
                    sectionID: sectionID,
                    number: record.number,
                    text: text,
                    shortText: short,
                    source: cleaned(record.source)
                )
            )
        }

        let books = bookAcc
            .sorted { lhs, rhs in
                if lhs.value.count == rhs.value.count {
                    return lhs.value.title < rhs.value.title
                }
                return lhs.value.count > rhs.value.count
            }
            .map { key, value in
                let contentType = DailyContentType.resolve(bookID: key, title: value.title)
                let summaryTitle: String
                let symbol: String

                switch contentType {
                case .hadith:
                    summaryTitle = "hadis"
                    symbol = "text.book.closed.fill"
                case .ayah:
                    summaryTitle = "ayet"
                    symbol = "book.pages.fill"
                case .dua:
                    summaryTitle = "dua"
                    symbol = "hands.and.sparkles.fill"
                }

                return HadithBook(
                    id: key,
                    title: value.title,
                    summary: "\(value.count) \(summaryTitle) • API",
                    coverSymbol: symbol,
                    isFeatured: true
                )
            }

        let sections = sectionAcc
            .sorted { lhs, rhs in lhs.value.count > rhs.value.count }
            .enumerated()
            .map { index, element in
                HadithSection(
                    id: element.value.bookID == "remote-featured" ? "api" : element.key.split(separator: "#").last.map(String.init) ?? "api",
                    bookID: element.value.bookID,
                    title: element.value.title,
                    order: index + 1
                )
            }

        let orderedBooks = books.map(\.id)
        let bookIndex = Dictionary(uniqueKeysWithValues: orderedBooks.enumerated().map { ($0.element, $0.offset) })
        let hadiths = hadithItems.sorted { lhs, rhs in
            let lIndex = bookIndex[lhs.bookID] ?? Int.max
            let rIndex = bookIndex[rhs.bookID] ?? Int.max
            if lIndex == rIndex {
                if lhs.number == rhs.number {
                    return lhs.id < rhs.id
                }
                return lhs.number < rhs.number
            }
            return lIndex < rIndex
        }

        return HadithCatalog(books: books, sections: sections, hadiths: hadiths)
    }

    func book(id: String) -> HadithBook? {
        bookByID[id]
    }

    func hadith(id: String) -> HadithItem? {
        hadithByID[id]
    }

    func sections(for bookID: String) -> [HadithSection] {
        sections.filter { $0.bookID == bookID }.sorted { $0.order < $1.order }
    }

    func section(bookID: String, sectionID: String) -> HadithSection? {
        sectionByCompositeID["\(bookID)#\(sectionID)"]
    }

    func hadiths(for bookID: String) -> [HadithItem] {
        hadiths.filter { $0.bookID == bookID }.sorted { $0.number < $1.number }
    }

    func featuredBooks() -> [HadithBook] {
        let featured = books.filter(\.isFeatured)
        return featured.isEmpty ? books : featured
    }

    func dailySelection(on date: Date, preferredBookID: String?, installSeed: Int) -> HadithDailySelection {
        let pool: [HadithItem]
        if let preferredBookID, !preferredBookID.isEmpty {
            let preferred = hadiths(for: preferredBookID)
            pool = preferred.isEmpty ? hadiths : preferred
        } else {
            let featuredIDs = Set(featuredBooks().map(\.id))
            let featuredPool = hadiths.filter { featuredIDs.contains($0.bookID) }
            pool = featuredPool.isEmpty ? hadiths : featuredPool
        }

        let safePool = pool.isEmpty ? hadiths : pool
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = abs(dayOfYear + installSeed) % max(1, safePool.count)
        let hadith = safePool[index]

        let selectedBook = book(id: hadith.bookID) ?? books.first ?? HadithBook(
            id: "fallback-book",
            title: "API Koleksiyonu",
            summary: "Hadisler",
            coverSymbol: "book.closed.fill",
            isFeatured: true
        )

        let selectedSection = section(bookID: hadith.bookID, sectionID: hadith.sectionID)
            ?? sections(for: hadith.bookID).first
            ?? HadithSection(id: "fallback-section", bookID: selectedBook.id, title: "Genel", order: 1)

        return HadithDailySelection(
            date: date,
            book: selectedBook,
            section: selectedSection,
            hadith: hadith,
            index: index
        )
    }

    private static func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func slug(_ value: String) -> String {
        let lowered = value.lowercased()
        let folded = lowered.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let replaced = folded.replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        return replaced.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
