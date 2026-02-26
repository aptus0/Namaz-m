import Foundation
import SQLite3

struct HadithRemoteRecord: Codable, Hashable, Identifiable {
    let id: String
    let number: Int
    let text: String
    let source: String
    let bookTitle: String
    let sectionTitle: String

    var shortText: String {
        if text.count <= 120 { return text }
        return "\(text.prefix(119))…"
    }
}

enum HadithSyncState: Equatable {
    case idle
    case syncing
    case synced(count: Int, date: Date)
    case failed(message: String)
}

protocol HadithRemoteProvider {
    nonisolated func fetchHadiths(limit: Int, language: AppLanguage) async throws -> [HadithRemoteRecord]
}

enum HadithSyncError: LocalizedError {
    case invalidResponse
    case sourceNotConfigured(String)
    case missingRemoteContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Hadith API yaniti cozumlenemedi."
        case .sourceNotConfigured(let reason):
            return reason
        case .missingRemoteContent:
            return "Canli icerik su an alinamiyor."
        }
    }
}

actor HadithCacheStore {
    private let cacheURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        cacheURL = appSupport.appendingPathComponent("hadith-cache.json")
    }

    func load() -> [HadithRemoteRecord] {
        guard let data = try? Data(contentsOf: cacheURL) else { return [] }
        guard let records = try? JSONDecoder().decode([HadithRemoteRecord].self, from: data) else { return [] }
        return records
    }

    func save(_ records: [HadithRemoteRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }

        let directory = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: .atomic)
    }
}

actor HadithSyncService {
    static let shared = HadithSyncService()

    private let cacheStore = HadithCacheStore()
    private let quranService = QuranSyncService.shared
    private nonisolated static let ayahSurahPriority = ["1", "36", "55", "67", "76", "112", "113", "114"]
    private nonisolated static let duaReferences: [(surahID: String, ayahNo: Int, title: String)] = [
        ("1", 5, "Yardim Duasi"),
        ("1", 6, "Hidayet Duasi"),
        ("1", 7, "Istikamet Duasi"),
        ("2", 201, "Dunya ve Ahiret Duasi"),
        ("2", 255, "Ayetel Kursi"),
        ("2", 286, "Bagislanma Duasi"),
        ("112", 1, "Ihlas Duasi"),
        ("113", 1, "Felak Duasi"),
        ("114", 1, "Nas Duasi")
    ]

    func loadCached() async -> [HadithRemoteRecord] {
        await cacheStore.load()
    }

    func sync(source: HadithSourceOption, language: AppLanguage, limit: Int = 400) async throws -> [HadithRemoteRecord] {
        _ = source

        do {
            let apiRecords = try await fetchQuranCollections(limit: limit)
            if !apiRecords.isEmpty {
                await cacheStore.save(apiRecords)
                return apiRecords
            }
        } catch {
            let contentPackRecords = try? await ContentPackProvider().fetchHadiths(limit: limit, language: language)
            if let contentPackRecords, !contentPackRecords.isEmpty {
                await cacheStore.save(contentPackRecords)
                return contentPackRecords
            }

            let cached = await cacheStore.load()
            if !cached.isEmpty {
                return cached
            }
            throw error
        }

        let cached = await cacheStore.load()
        if !cached.isEmpty {
            return cached
        }

        throw HadithSyncError.missingRemoteContent
    }

    private func fetchQuranCollections(limit: Int) async throws -> [HadithRemoteRecord] {
        let isConfigured = await MainActor.run { QuranAPIConfig.isConfigured }
        guard isConfigured else {
            throw HadithSyncError.sourceNotConfigured("Quran API ayarlari eksik.")
        }

        let surahs = try await loadSurahsForContent()
        guard !surahs.isEmpty else {
            throw HadithSyncError.invalidResponse
        }

        let surahByID = Dictionary(uniqueKeysWithValues: surahs.map { ($0.id, $0) })
        let selectedAyahSurahIDs = preferredAyahSurahIDs(from: surahs)
        let requiredSurahIDs = Set(selectedAyahSurahIDs + Self.duaReferences.map(\.surahID))

        var ayahsBySurahID: [String: [QuranAyah]] = [:]
        for surahID in requiredSurahIDs {
            let values = try await loadAyahs(surahID: surahID)
            if !values.isEmpty {
                ayahsBySurahID[surahID] = values
            }
        }

        let ayahLimit = max(24, min(limit, 220))
        let ayahRecords = buildAyahRecords(
            surahIDs: selectedAyahSurahIDs,
            surahByID: surahByID,
            ayahsBySurahID: ayahsBySurahID,
            limit: ayahLimit
        )

        let remainingLimit = max(12, limit - ayahRecords.count)
        let duaRecords = buildDuaRecords(
            surahByID: surahByID,
            ayahsBySurahID: ayahsBySurahID,
            limit: remainingLimit
        )

        let merged = deduplicated(records: ayahRecords + duaRecords)
        guard !merged.isEmpty else {
            throw HadithSyncError.invalidResponse
        }
        return merged
    }

    private func loadSurahsForContent() async throws -> [QuranSurah] {
        do {
            return try await quranService.syncSurahs()
        } catch {
            let cached = await quranService.loadCachedSurahs()
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    private func loadAyahs(surahID: String) async throws -> [QuranAyah] {
        do {
            return try await quranService.ayahs(for: surahID, forceRefresh: false)
        } catch {
            return try await quranService.ayahs(for: surahID, forceRefresh: true)
        }
    }

    private func preferredAyahSurahIDs(from surahs: [QuranSurah]) -> [String] {
        let available = Set(surahs.map(\.id))
        var selected = Self.ayahSurahPriority.filter { available.contains($0) }

        if selected.count < 6 {
            let fallback = surahs
                .sorted { $0.order < $1.order }
                .map(\.id)
                .filter { !selected.contains($0) }
                .prefix(6 - selected.count)
            selected.append(contentsOf: fallback)
        }

        return selected
    }

    private func buildAyahRecords(
        surahIDs: [String],
        surahByID: [String: QuranSurah],
        ayahsBySurahID: [String: [QuranAyah]],
        limit: Int
    ) -> [HadithRemoteRecord] {
        var records: [HadithRemoteRecord] = []
        records.reserveCapacity(limit)

        for surahID in surahIDs {
            guard let surah = surahByID[surahID] else { continue }
            let surahName = preferredSurahName(surah)
            let ayahs = ayahsBySurahID[surahID] ?? []

            for ayah in ayahs {
                guard records.count < limit else { break }
                let text = composedText(for: ayah)
                if text.isEmpty { continue }

                records.append(
                    HadithRemoteRecord(
                        id: "ayah-\(surahID)-\(ayah.ayahNo)",
                        number: ayah.ayahNo,
                        text: text,
                        source: "Kur'an • \(surahName) \(ayah.ayahNo)",
                        bookTitle: "Kur'an Ayetleri",
                        sectionTitle: surahName
                    )
                )
            }
        }

        return records
    }

    private func buildDuaRecords(
        surahByID: [String: QuranSurah],
        ayahsBySurahID: [String: [QuranAyah]],
        limit: Int
    ) -> [HadithRemoteRecord] {
        var records: [HadithRemoteRecord] = []
        records.reserveCapacity(limit)

        for reference in Self.duaReferences {
            guard records.count < limit else { break }
            guard
                let ayah = ayahsBySurahID[reference.surahID]?.first(where: { $0.ayahNo == reference.ayahNo }),
                let surah = surahByID[reference.surahID]
            else {
                continue
            }

            let surahName = preferredSurahName(surah)
            let text = composedText(for: ayah)
            if text.isEmpty { continue }

            records.append(
                HadithRemoteRecord(
                    id: "dua-\(reference.surahID)-\(reference.ayahNo)",
                    number: records.count + 1,
                    text: text,
                    source: "Kur'an • \(surahName) \(reference.ayahNo)",
                    bookTitle: "Kur'an Dualari",
                    sectionTitle: reference.title
                )
            )
        }

        return records
    }

    private func composedText(for ayah: QuranAyah) -> String {
        let arabic = ayah.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let translation = ayah.translation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !translation.isEmpty && !arabic.isEmpty {
            return "\(translation)\n\n\(arabic)"
        }

        return !translation.isEmpty ? translation : arabic
    }

    private func preferredSurahName(_ surah: QuranSurah) -> String {
        let turkish = surah.nameTr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !turkish.isEmpty {
            return turkish
        }

        let arabic = surah.nameAr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !arabic.isEmpty {
            return arabic
        }

        return "Sure \(surah.id)"
    }

    private func deduplicated(records: [HadithRemoteRecord]) -> [HadithRemoteRecord] {
        var seen = Set<String>()
        var output: [HadithRemoteRecord] = []
        output.reserveCapacity(records.count)

        for record in records where !seen.contains(record.id) {
            seen.insert(record.id)
            output.append(record)
        }

        return output
    }
}

struct ContentPackProvider: HadithRemoteProvider {
    nonisolated init() {}

    nonisolated func fetchHadiths(limit: Int, language: AppLanguage) async throws -> [HadithRemoteRecord] {
        try await ContentPackStore.shared.loadHadithRecords(limit: limit, language: language)
    }
}

enum ContentPackStoreError: LocalizedError {
    case openFailed
    case statementFailed
    case readFailed

    var errorDescription: String? {
        switch self {
        case .openFailed:
            return "Content pack veritabani acilamadi."
        case .statementFailed:
            return "Content pack sorgusu calistirilamadi."
        case .readFailed:
            return "Content pack verisi okunamadi."
        }
    }
}

actor ContentPackStore {
    static let shared = ContentPackStore()

    private let fileManager = FileManager.default
    private let databaseURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        databaseURL = appSupport.appendingPathComponent("content-pack/content.sqlite", isDirectory: false)
    }

    func loadHadithRecords(limit: Int, language: AppLanguage) throws -> [HadithRemoteRecord] {
        try prepareDatabaseIfNeeded(language: language)
        let database = try openDatabase(at: databaseURL)
        defer { sqlite3_close(database) }

        let query = """
        SELECT
            items.id,
            items.order_index,
            items.text,
            COALESCE(NULLIF(items.ref, ''), NULLIF(books.source_note, ''), 'Content Pack') AS source,
            books.title,
            sections.title
        FROM items
        INNER JOIN books ON books.id = items.book_id
        INNER JOIN sections ON sections.id = items.section_id
        WHERE books.type = 'HADITH'
          AND (books.language = ?1 OR books.language = 'all' OR books.language = '')
        ORDER BY books.id ASC, items.order_index ASC
        LIMIT ?2;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw ContentPackStoreError.statementFailed
        }
        defer { sqlite3_finalize(statement) }

        bindText(languageCode(for: language), index: 1, statement: statement)
        sqlite3_bind_int(statement, 2, Int32(max(1, limit)))

        var records: [HadithRemoteRecord] = []
        records.reserveCapacity(max(32, min(limit, 800)))

        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let id = readString(statement, column: 0),
                let text = readString(statement, column: 2),
                let source = readString(statement, column: 3),
                let bookTitle = readString(statement, column: 4),
                let sectionTitle = readString(statement, column: 5)
            else {
                continue
            }

            let number = Int(sqlite3_column_int(statement, 1))
            records.append(
                HadithRemoteRecord(
                    id: id,
                    number: max(1, number),
                    text: text,
                    source: source,
                    bookTitle: bookTitle,
                    sectionTitle: sectionTitle
                )
            )
        }

        if records.isEmpty {
            throw ContentPackStoreError.readFailed
        }

        return records
    }

    private func prepareDatabaseIfNeeded(language: AppLanguage) throws {
        let directory = databaseURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        if !fileManager.fileExists(atPath: databaseURL.path),
           let bundledURL = bundledPackURL(for: language) {
            try? fileManager.removeItem(at: databaseURL)
            try fileManager.copyItem(at: bundledURL, to: databaseURL)
        }

        let database = try openDatabase(at: databaseURL)
        defer { sqlite3_close(database) }

        try execute(
            """
            PRAGMA foreign_keys = ON;

            CREATE TABLE IF NOT EXISTS books (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                type TEXT NOT NULL,
                language TEXT NOT NULL,
                cover TEXT,
                description TEXT,
                source_note TEXT
            );

            CREATE TABLE IF NOT EXISTS sections (
                id TEXT PRIMARY KEY,
                book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
                title TEXT NOT NULL,
                order_index INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS items (
                id TEXT PRIMARY KEY,
                book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
                section_id TEXT NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
                order_index INTEGER NOT NULL,
                title TEXT,
                text TEXT NOT NULL,
                short_text TEXT NOT NULL,
                ref TEXT,
                tags TEXT
            );

            CREATE TABLE IF NOT EXISTS favorites (
                item_id TEXT PRIMARY KEY,
                created_at REAL NOT NULL
            );

            CREATE TABLE IF NOT EXISTS reading_progress (
                book_id TEXT PRIMARY KEY,
                section_id TEXT,
                item_id TEXT,
                updated_at REAL NOT NULL
            );

            CREATE TABLE IF NOT EXISTS meta (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            """,
            database: database
        )

        let seedCount = try countRows(table: "items", database: database)
        if seedCount == 0 {
            try seedDatabase(database: database, language: language)
        }
    }

    private func bundledPackURL(for language: AppLanguage) -> URL? {
        let code = languageCode(for: language)
        let names = ["base_\(code).pack", "base_\(code)", "base_tr.pack", "base_tr"]
        let extensions = ["sqlite", "db"]

        for name in names {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/ContentPacks") {
                    return url
                }
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    return url
                }
            }
        }

        return nil
    }

    private func seedDatabase(database: OpaquePointer?, language: AppLanguage) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION;", database: database)
        do {
            try seedBooks(database: database, language: language)
            try seedSections(database: database)
            try seedItems(database: database)
            try seedMeta(database: database, language: language)
            try execute("COMMIT;", database: database)
        } catch {
            try? execute("ROLLBACK;", database: database)
            throw error
        }
    }

    private func seedBooks(database: OpaquePointer?, language: AppLanguage) throws {
        let sql = """
        INSERT OR REPLACE INTO books (id, title, type, language, cover, description, source_note)
        VALUES (?1, ?2, 'HADITH', ?3, ?4, ?5, ?6);
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw ContentPackStoreError.statementFailed
        }
        defer { sqlite3_finalize(statement) }

        let languageCode = languageCode(for: language)
        for book in HadithRepository.books {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)

            bindText(book.id, index: 1, statement: statement)
            bindText(book.title, index: 2, statement: statement)
            bindText(languageCode, index: 3, statement: statement)
            bindText(book.coverSymbol, index: 4, statement: statement)
            bindText(book.summary, index: 5, statement: statement)
            bindText("Namazim base content pack", index: 6, statement: statement)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw ContentPackStoreError.statementFailed
            }
        }
    }

    private func seedSections(database: OpaquePointer?) throws {
        let sql = """
        INSERT OR REPLACE INTO sections (id, book_id, title, order_index)
        VALUES (?1, ?2, ?3, ?4);
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw ContentPackStoreError.statementFailed
        }
        defer { sqlite3_finalize(statement) }

        for section in HadithRepository.sections {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)

            bindText(section.id, index: 1, statement: statement)
            bindText(section.bookID, index: 2, statement: statement)
            bindText(section.title, index: 3, statement: statement)
            sqlite3_bind_int(statement, 4, Int32(section.order))

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw ContentPackStoreError.statementFailed
            }
        }
    }

    private func seedItems(database: OpaquePointer?) throws {
        let sql = """
        INSERT OR REPLACE INTO items (id, book_id, section_id, order_index, title, text, short_text, ref, tags)
        VALUES (?1, ?2, ?3, ?4, NULL, ?5, ?6, ?7, NULL);
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw ContentPackStoreError.statementFailed
        }
        defer { sqlite3_finalize(statement) }

        for item in HadithRepository.hadiths {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)

            bindText(item.id, index: 1, statement: statement)
            bindText(item.bookID, index: 2, statement: statement)
            bindText(item.sectionID, index: 3, statement: statement)
            sqlite3_bind_int(statement, 4, Int32(item.number))
            bindText(item.text, index: 5, statement: statement)
            bindText(item.shortText, index: 6, statement: statement)
            bindText(item.source, index: 7, statement: statement)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw ContentPackStoreError.statementFailed
            }
        }
    }

    private func seedMeta(database: OpaquePointer?, language: AppLanguage) throws {
        let sql = "INSERT OR REPLACE INTO meta (key, value) VALUES (?1, ?2);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw ContentPackStoreError.statementFailed
        }
        defer { sqlite3_finalize(statement) }

        let rows: [(String, String)] = [
            ("contentVersion", "base_\(languageCode(for: language))_001"),
            ("lastUpdateCheck", String(Int(Date().timeIntervalSince1970)))
        ]

        for row in rows {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)

            bindText(row.0, index: 1, statement: statement)
            bindText(row.1, index: 2, statement: statement)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw ContentPackStoreError.statementFailed
            }
        }
    }

    private func countRows(table: String, database: OpaquePointer?) throws -> Int {
        let query = "SELECT COUNT(*) FROM \(table);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw ContentPackStoreError.statementFailed
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw ContentPackStoreError.readFailed
        }

        return Int(sqlite3_column_int(statement, 0))
    }

    private func execute(_ sql: String, database: OpaquePointer?) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw ContentPackStoreError.statementFailed
        }
    }

    private func openDatabase(at url: URL) throws -> OpaquePointer? {
        var database: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &database, flags, nil) == SQLITE_OK else {
            if database != nil {
                sqlite3_close(database)
            }
            throw ContentPackStoreError.openFailed
        }

        return database
    }

    private func bindText(_ value: String, index: Int32, statement: OpaquePointer?) {
        sqlite3_bind_text(statement, index, value, -1, sqliteTransientDestructor)
    }

    private func readString(_ statement: OpaquePointer?, column: Int32) -> String? {
        guard let pointer = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: pointer)
    }

    private func languageCode(for language: AppLanguage) -> String {
        switch language {
        case .system:
            let first = Locale.preferredLanguages.first ?? "tr"
            let code = first.split(separator: "-").first.map(String.init) ?? "tr"
            return code.lowercased()
        case .tr:
            return "tr"
        case .en:
            return "en"
        case .ar:
            return "ar"
        case .de:
            return "de"
        }
    }
}

nonisolated(unsafe) private let sqliteTransientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
