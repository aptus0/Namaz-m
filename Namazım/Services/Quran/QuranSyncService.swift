import Foundation
import SQLite3
import CoreText

enum QuranSyncError: LocalizedError {
    case apiNotConfigured
    case invalidResponse
    case fontDownloadURLMissing
    case fontNotFound

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured:
            return "Quran API bilgileri eksik. Info.plist anahtarlarini kontrol edin."
        case .invalidResponse:
            return "Quran API yaniti cozumlenemedi."
        case .fontDownloadURLMissing:
            return "Secilen yazi tipi icin indirme baglantisi bulunamadi."
        case .fontNotFound:
            return "Secilen yazi tipi bulunamadi."
        }
    }
}

private struct QuranJSONParser {
    typealias JSON = [String: Any]

    static func objects(from data: Data, preferredArrayKeys: [String] = []) throws -> [JSON] {
        let raw = try JSONSerialization.jsonObject(with: data)

        if let array = raw as? [JSON] {
            return array
        }

        if let dict = raw as? JSON {
            for key in preferredArrayKeys {
                if let array = nestedArray(for: key, in: dict), !array.isEmpty {
                    return array
                }
            }

            let genericKeys = ["data", "result", "results", "items", "fonts", "surahs", "ayahs", "juzs"]
            for key in genericKeys {
                if let array = nestedArray(for: key, in: dict), !array.isEmpty {
                    return array
                }
            }

            if !dict.isEmpty {
                return [dict]
            }
        }

        throw QuranSyncError.invalidResponse
    }

    static func string(_ keys: [String], in object: JSON) -> String? {
        for key in keys {
            if let value = value(for: key, in: object) {
                if let string = value as? String {
                    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        return trimmed
                    }
                } else if let number = value as? NSNumber {
                    return number.stringValue
                }
            }
        }

        return nil
    }

    static func int(_ keys: [String], in object: JSON) -> Int? {
        for key in keys {
            if let value = value(for: key, in: object) {
                if let number = value as? NSNumber {
                    return number.intValue
                }

                if let string = value as? String,
                   let parsed = Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return parsed
                }
            }
        }

        return nil
    }

    static func url(_ keys: [String], in object: JSON) -> URL? {
        guard let raw = string(keys, in: object) else { return nil }
        return URL(string: raw)
    }

    private static func nestedArray(for key: String, in dict: JSON) -> [JSON]? {
        guard let value = value(for: key, in: dict) else { return nil }

        if let direct = value as? [JSON] {
            return direct
        }

        if let nested = value as? JSON {
            let nestedKeys = ["items", "results", "fonts", "surahs", "ayahs", "juzs", "data"]
            for nestedKey in nestedKeys {
                if let nestedArray = nested[nestedKey] as? [JSON], !nestedArray.isEmpty {
                    return nestedArray
                }
            }
        }

        return nil
    }

    private static func value(for dottedKey: String, in object: JSON) -> Any? {
        if dottedKey.contains(".") {
            let pieces = dottedKey.split(separator: ".").map(String.init)
            var current: Any? = object
            for piece in pieces {
                guard let dict = current as? JSON else {
                    current = nil
                    break
                }
                current = dict[piece]
            }
            return current
        }

        return object[dottedKey]
    }
}

struct QuranAPIClient {
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchFonts() async throws -> [QuranFont] {
        let data = try await request(path: QuranAPIConfig.fontsPath)
        let objects = try QuranJSONParser.objects(from: data, preferredArrayKeys: ["data.fonts", "data"])

        var result: [QuranFont] = []
        for object in objects {
            let id = QuranJSONParser.string(["id", "fontId", "font_id", "slug", "code"], in: object)
                ?? UUID().uuidString
            let displayName = QuranJSONParser.string(
                ["displayName", "display_name", "name", "title", "file_name"],
                in: object
            )
                ?? "Font \(id)"
            let style = QuranJSONParser.string(["style", "type", "category"], in: object)
            let downloadURL = QuranJSONParser.url(
                ["downloadUrl", "download_url", "url", "fileUrl", "file_url", "asset.url"],
                in: object
            )
            let postScriptName = QuranJSONParser.string(
                ["postScriptName", "post_script_name", "fontFamily", "font_family"],
                in: object
            )

            result.append(
                QuranFont(
                    id: id,
                    displayName: displayName,
                    style: style,
                    downloadURL: downloadURL,
                    localPath: nil,
                    postScriptName: postScriptName,
                    isDownloaded: false
                )
            )
        }

        return deduplicatedFonts(result)
    }

    func fetchSurahs() async throws -> [QuranSurah] {
        let data = try await request(path: QuranAPIConfig.surahsPath)
        let objects = try QuranJSONParser.objects(from: data, preferredArrayKeys: ["data.surahs", "data"])

        var result: [QuranSurah] = []
        for object in objects {
            let order = QuranJSONParser.int(
                ["order", "index", "number", "surahNo", "id", "SureId", "surah_id", "surahId"],
                in: object
            ) ?? 0
            let resolvedID = QuranJSONParser.string(
                ["id", "surahId", "surah_id", "SureId", "chapter_id", "ChapterId"],
                in: object
            ) ?? String(max(1, order))

            let nameTr = QuranJSONParser.string(
                ["nameTr", "name_tr", "nameLatin", "name_latin", "name", "title", "SureNameTurkish", "surah_name_turkish"],
                in: object
            ) ?? "Sure \(resolvedID)"
            let nameAr = QuranJSONParser.string(
                ["nameAr", "name_ar", "nameArabic", "name_arabic", "arabicName", "arabic_name", "SureNameArabic", "surah_name_arabic"],
                in: object
            ) ?? ""
            let verseCount = QuranJSONParser.int(
                ["verseCount", "verse_count", "ayahCount", "ayah_count", "numberOfAyahs", "count", "AyetCount", "ayet_count"],
                in: object
            ) ?? 0
            let normalizedOrder = max(1, order == 0 ? (Int(resolvedID) ?? 1) : order)

            result.append(
                QuranSurah(
                    id: resolvedID,
                    nameTr: nameTr,
                    nameAr: nameAr,
                    verseCount: max(0, verseCount),
                    order: normalizedOrder
                )
            )
        }

        return deduplicatedSurahs(result)
    }

    func fetchAyahs(surahID: String) async throws -> [QuranAyah] {
        let path = QuranAPIConfig.ayahsPath(surahID: surahID)
        let data = try await request(path: path)
        let objects = try QuranJSONParser.objects(from: data, preferredArrayKeys: ["data.ayahs", "data.items", "data"])

        var result: [QuranAyah] = []
        for object in objects {
            let ayahNo = QuranJSONParser.int(
                ["ayahNo", "ayah_no", "numberInSurah", "verse", "order", "id", "verse_id_in_surah", "verseIdInSurah"],
                in: object
            ) ?? 0
            let text = QuranJSONParser.string(
                ["text", "arabicText", "arabic_text", "content", "value", "arabic_script.text", "arabicScript.text"],
                in: object
            ) ?? ""

            if text.isEmpty {
                continue
            }

            let translation = QuranJSONParser.string(
                ["translation", "meal", "textTr", "text_tr", "translation.text"],
                in: object
            )
            let pageNo = QuranJSONParser.int(["pageNo", "page_no", "page", "page_number"], in: object)
            let juzNo = QuranJSONParser.int(["juzNo", "juz_no", "juz", "juzNumber"], in: object)
            let resolvedSurahID = QuranJSONParser.string(["surah_id", "surahId", "SureId"], in: object) ?? surahID

            let normalizedAyahNo = max(1, ayahNo)
            result.append(
                QuranAyah(
                    id: "\(resolvedSurahID)-\(normalizedAyahNo)",
                    surahID: resolvedSurahID,
                    ayahNo: normalizedAyahNo,
                    text: text,
                    translation: translation,
                    pageNo: pageNo,
                    juzNo: juzNo
                )
            )
        }

        return deduplicatedAyahs(result)
    }

    func fetchJuzs() async throws -> [QuranJuz] {
        let chaptersData = try await request(path: QuranAPIConfig.surahsPath)
        let chapterObjects = try QuranJSONParser.objects(from: chaptersData, preferredArrayKeys: ["data.surahs", "data"])

        var startSurahByJuz: [Int: Int] = [:]
        for object in chapterObjects {
            guard
                let juzNo = QuranJSONParser.int(["Cuz", "cuz", "juz", "juzNo", "juz_no"], in: object),
                let surahNo = QuranJSONParser.int(["SureId", "id", "surah_id", "surahId", "number"], in: object)
            else {
                continue
            }

            if let current = startSurahByJuz[juzNo] {
                startSurahByJuz[juzNo] = min(current, surahNo)
            } else {
                startSurahByJuz[juzNo] = surahNo
            }
        }

        if !startSurahByJuz.isEmpty {
            let orderedJuzs = startSurahByJuz.keys.sorted()
            var result: [QuranJuz] = []
            result.reserveCapacity(orderedJuzs.count)

            for index in orderedJuzs.indices {
                let juzNo = orderedJuzs[index]
                guard let startSurahNo = startSurahByJuz[juzNo] else { continue }

                let nextStartSurahNo: Int? = {
                    guard index + 1 < orderedJuzs.count else { return nil }
                    let nextJuzNo = orderedJuzs[index + 1]
                    return startSurahByJuz[nextJuzNo]
                }()

                let endSurahID = nextStartSurahNo.map { String(max(1, $0 - 1)) }

                result.append(
                    QuranJuz(
                        id: String(juzNo),
                        startSurahID: String(startSurahNo),
                        startAyahNo: 1,
                        endSurahID: endSurahID,
                        endAyahNo: nil
                    )
                )
            }

            return deduplicatedJuzs(result)
        }

        let template = QuranAPIConfig.juzsPathTemplate
        let resolvedPath = template.contains("{juzId}") || template.contains("{juz_id}")
            ? QuranAPIConfig.juzPath(juzID: 1)
            : template

        let data = try await request(path: resolvedPath)
        let objects = try QuranJSONParser.objects(from: data, preferredArrayKeys: ["data.juzs", "data"])
        guard let first = objects.first else {
            throw QuranSyncError.invalidResponse
        }
        let last = objects.last ?? first

        let startSurahID = QuranJSONParser.string(
            ["startSurahId", "start_surah_id", "start.surahId", "start.surah_id", "surah_id", "surahId"],
            in: first
        ) ?? "1"
        let startAyahNo = QuranJSONParser.int(
            ["startAyahNo", "start_ayah_no", "start.ayahNo", "start.ayah_no", "verse_id_in_surah"],
            in: first
        ) ?? 1
        let endSurahID = QuranJSONParser.string(
            ["endSurahId", "end_surah_id", "end.surahId", "end.surah_id", "surah_id", "surahId"],
            in: last
        )
        let endAyahNo = QuranJSONParser.int(
            ["endAyahNo", "end_ayah_no", "end.ayahNo", "end.ayah_no", "verse_id_in_surah"],
            in: last
        )

        return [
            QuranJuz(
                id: "1",
                startSurahID: startSurahID,
                startAyahNo: max(1, startAyahNo),
                endSurahID: endSurahID,
                endAyahNo: endAyahNo
            )
        ]
    }

    private func request(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        guard QuranAPIConfig.isConfigured, let baseURL = QuranAPIConfig.baseURL else {
            throw QuranSyncError.apiNotConfigured
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let joinedPath = path.hasPrefix("/") ? path : "/\(path)"
        let basePath = components?.path ?? ""
        let normalizedBasePath = basePath.hasSuffix("/") ? String(basePath.dropLast()) : basePath
        components?.path = "\(normalizedBasePath)\(joinedPath)"
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw QuranSyncError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        let keyHeader = QuranAPIConfig.apiKeyHeader
        let key = QuranAPIConfig.apiKey
        if keyHeader.caseInsensitiveCompare("Authorization") == .orderedSame {
            let prefix = QuranAPIConfig.apiAuthPrefix
            if key.lowercased().hasPrefix(prefix.lowercased()) {
                request.setValue(key, forHTTPHeaderField: keyHeader)
            } else {
                request.setValue("\(prefix) \(key)", forHTTPHeaderField: keyHeader)
            }
        } else {
            request.setValue(key, forHTTPHeaderField: keyHeader)
        }

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw QuranSyncError.invalidResponse
        }

        return data
    }

    private func deduplicatedFonts(_ fonts: [QuranFont]) -> [QuranFont] {
        var seen = Set<String>()
        var output: [QuranFont] = []
        output.reserveCapacity(fonts.count)

        for font in fonts where !seen.contains(font.id) {
            seen.insert(font.id)
            output.append(font)
        }

        return output
    }

    private func deduplicatedSurahs(_ surahs: [QuranSurah]) -> [QuranSurah] {
        var seen = Set<String>()
        var output: [QuranSurah] = []
        output.reserveCapacity(surahs.count)

        for surah in surahs where !seen.contains(surah.id) {
            seen.insert(surah.id)
            output.append(surah)
        }

        return output.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.id < rhs.id
            }
            return lhs.order < rhs.order
        }
    }

    private func deduplicatedAyahs(_ ayahs: [QuranAyah]) -> [QuranAyah] {
        var seen = Set<String>()
        var output: [QuranAyah] = []
        output.reserveCapacity(ayahs.count)

        for ayah in ayahs where !seen.contains(ayah.id) {
            seen.insert(ayah.id)
            output.append(ayah)
        }

        return output.sorted { $0.ayahNo < $1.ayahNo }
    }

    private func deduplicatedJuzs(_ juzs: [QuranJuz]) -> [QuranJuz] {
        var seen = Set<String>()
        var output: [QuranJuz] = []
        output.reserveCapacity(juzs.count)

        for juz in juzs where !seen.contains(juz.id) {
            seen.insert(juz.id)
            output.append(juz)
        }

        return output.sorted { $0.id < $1.id }
    }
}

actor QuranCacheStore {
    static let shared = QuranCacheStore()

    private let databaseURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        databaseURL = appSupport.appendingPathComponent("quran-cache.sqlite")
    }

    func loadFonts() throws -> [QuranFont] {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        let sql = """
        SELECT id, display_name, style, download_url, local_path, postscript_name, is_downloaded
        FROM fonts
        ORDER BY display_name ASC;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw QuranSyncError.invalidResponse
        }
        defer { sqlite3_finalize(statement) }

        var fonts: [QuranFont] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let id = readString(statement, column: 0),
                let displayName = readString(statement, column: 1)
            else {
                continue
            }

            let style = readString(statement, column: 2)
            let downloadURL = readString(statement, column: 3).flatMap(URL.init(string:))
            let localPath = readString(statement, column: 4)
            let postScriptName = readString(statement, column: 5)
            let isDownloaded = sqlite3_column_int(statement, 6) == 1

            fonts.append(
                QuranFont(
                    id: id,
                    displayName: displayName,
                    style: style,
                    downloadURL: downloadURL,
                    localPath: localPath,
                    postScriptName: postScriptName,
                    isDownloaded: isDownloaded
                )
            )
        }

        return fonts
    }

    func saveFonts(_ fonts: [QuranFont]) throws {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        try execute("BEGIN IMMEDIATE TRANSACTION;", database: database)
        do {
            try execute("DELETE FROM fonts;", database: database)

            let sql = """
            INSERT INTO fonts (id, display_name, style, download_url, local_path, postscript_name, is_downloaded, updated_at)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8);
            """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
                throw QuranSyncError.invalidResponse
            }
            defer { sqlite3_finalize(statement) }

            let now = Date().timeIntervalSince1970
            for font in fonts {
                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)

                bindText(font.id, index: 1, statement: statement)
                bindText(font.displayName, index: 2, statement: statement)
                bindOptionalText(font.style, index: 3, statement: statement)
                bindOptionalText(font.downloadURL?.absoluteString, index: 4, statement: statement)
                bindOptionalText(font.localPath, index: 5, statement: statement)
                bindOptionalText(font.postScriptName, index: 6, statement: statement)
                sqlite3_bind_int(statement, 7, font.isDownloaded ? 1 : 0)
                sqlite3_bind_double(statement, 8, now)

                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw QuranSyncError.invalidResponse
                }
            }

            try execute("COMMIT;", database: database)
        } catch {
            try? execute("ROLLBACK;", database: database)
            throw error
        }
    }

    func loadSurahs() throws -> [QuranSurah] {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        let sql = """
        SELECT id, name_tr, name_ar, verse_count, order_index
        FROM surahs
        ORDER BY order_index ASC;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw QuranSyncError.invalidResponse
        }
        defer { sqlite3_finalize(statement) }

        var output: [QuranSurah] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let id = readString(statement, column: 0),
                let nameTr = readString(statement, column: 1),
                let nameAr = readString(statement, column: 2)
            else {
                continue
            }

            output.append(
                QuranSurah(
                    id: id,
                    nameTr: nameTr,
                    nameAr: nameAr,
                    verseCount: Int(sqlite3_column_int(statement, 3)),
                    order: Int(sqlite3_column_int(statement, 4))
                )
            )
        }

        return output
    }

    func saveSurahs(_ surahs: [QuranSurah]) throws {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        try execute("BEGIN IMMEDIATE TRANSACTION;", database: database)
        do {
            try execute("DELETE FROM surahs;", database: database)

            let sql = """
            INSERT INTO surahs (id, name_tr, name_ar, verse_count, order_index)
            VALUES (?1, ?2, ?3, ?4, ?5);
            """

            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
                throw QuranSyncError.invalidResponse
            }
            defer { sqlite3_finalize(statement) }

            for surah in surahs {
                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)

                bindText(surah.id, index: 1, statement: statement)
                bindText(surah.nameTr, index: 2, statement: statement)
                bindText(surah.nameAr, index: 3, statement: statement)
                sqlite3_bind_int(statement, 4, Int32(surah.verseCount))
                sqlite3_bind_int(statement, 5, Int32(surah.order))

                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw QuranSyncError.invalidResponse
                }
            }

            try execute("COMMIT;", database: database)
        } catch {
            try? execute("ROLLBACK;", database: database)
            throw error
        }
    }

    func loadAyahs(surahID: String) throws -> [QuranAyah] {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        let sql = """
        SELECT id, surah_id, ayah_no, text, translation, page_no, juz_no
        FROM ayahs
        WHERE surah_id = ?1
        ORDER BY ayah_no ASC;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw QuranSyncError.invalidResponse
        }
        defer { sqlite3_finalize(statement) }

        bindText(surahID, index: 1, statement: statement)

        var output: [QuranAyah] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let id = readString(statement, column: 0),
                let rowSurahID = readString(statement, column: 1),
                let text = readString(statement, column: 3)
            else {
                continue
            }

            let translation = readString(statement, column: 4)
            let pageNo = sqlite3_column_type(statement, 5) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 5))
            let juzNo = sqlite3_column_type(statement, 6) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 6))

            output.append(
                QuranAyah(
                    id: id,
                    surahID: rowSurahID,
                    ayahNo: Int(sqlite3_column_int(statement, 2)),
                    text: text,
                    translation: translation,
                    pageNo: pageNo,
                    juzNo: juzNo
                )
            )
        }

        return output
    }

    func saveAyahs(_ ayahs: [QuranAyah], surahID: String) throws {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        try execute("BEGIN IMMEDIATE TRANSACTION;", database: database)
        do {
            var deleteStatement: OpaquePointer?
            guard sqlite3_prepare_v2(database, "DELETE FROM ayahs WHERE surah_id = ?1;", -1, &deleteStatement, nil) == SQLITE_OK else {
                throw QuranSyncError.invalidResponse
            }
            bindText(surahID, index: 1, statement: deleteStatement)
            guard sqlite3_step(deleteStatement) == SQLITE_DONE else {
                sqlite3_finalize(deleteStatement)
                throw QuranSyncError.invalidResponse
            }
            sqlite3_finalize(deleteStatement)

            let sql = """
            INSERT INTO ayahs (id, surah_id, ayah_no, text, translation, page_no, juz_no)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7);
            """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
                throw QuranSyncError.invalidResponse
            }
            defer { sqlite3_finalize(statement) }

            for ayah in ayahs {
                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)

                bindText(ayah.id, index: 1, statement: statement)
                bindText(ayah.surahID, index: 2, statement: statement)
                sqlite3_bind_int(statement, 3, Int32(ayah.ayahNo))
                bindText(ayah.text, index: 4, statement: statement)
                bindOptionalText(ayah.translation, index: 5, statement: statement)
                bindOptionalInt(ayah.pageNo, index: 6, statement: statement)
                bindOptionalInt(ayah.juzNo, index: 7, statement: statement)

                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw QuranSyncError.invalidResponse
                }
            }

            try execute("COMMIT;", database: database)
        } catch {
            try? execute("ROLLBACK;", database: database)
            throw error
        }
    }

    func loadJuzs() throws -> [QuranJuz] {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        let sql = """
        SELECT id, start_surah_id, start_ayah_no, end_surah_id, end_ayah_no
        FROM juzs
        ORDER BY CAST(id AS INTEGER) ASC, id ASC;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw QuranSyncError.invalidResponse
        }
        defer { sqlite3_finalize(statement) }

        var output: [QuranJuz] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let id = readString(statement, column: 0),
                let startSurahID = readString(statement, column: 1)
            else {
                continue
            }

            let endSurahID = readString(statement, column: 3)
            let endAyahNo = sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 4))

            output.append(
                QuranJuz(
                    id: id,
                    startSurahID: startSurahID,
                    startAyahNo: Int(sqlite3_column_int(statement, 2)),
                    endSurahID: endSurahID,
                    endAyahNo: endAyahNo
                )
            )
        }

        return output
    }

    func saveJuzs(_ juzs: [QuranJuz]) throws {
        try prepareIfNeeded()
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        try execute("BEGIN IMMEDIATE TRANSACTION;", database: database)
        do {
            try execute("DELETE FROM juzs;", database: database)

            let sql = """
            INSERT INTO juzs (id, start_surah_id, start_ayah_no, end_surah_id, end_ayah_no)
            VALUES (?1, ?2, ?3, ?4, ?5);
            """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
                throw QuranSyncError.invalidResponse
            }
            defer { sqlite3_finalize(statement) }

            for juz in juzs {
                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)

                bindText(juz.id, index: 1, statement: statement)
                bindText(juz.startSurahID, index: 2, statement: statement)
                sqlite3_bind_int(statement, 3, Int32(juz.startAyahNo))
                bindOptionalText(juz.endSurahID, index: 4, statement: statement)
                bindOptionalInt(juz.endAyahNo, index: 5, statement: statement)

                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw QuranSyncError.invalidResponse
                }
            }

            try execute("COMMIT;", database: database)
        } catch {
            try? execute("ROLLBACK;", database: database)
            throw error
        }
    }

    private func prepareIfNeeded() throws {
        let directory = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let database = try openDatabase()
        defer { sqlite3_close(database) }

        try execute(
            """
            CREATE TABLE IF NOT EXISTS fonts (
                id TEXT PRIMARY KEY,
                display_name TEXT NOT NULL,
                style TEXT,
                download_url TEXT,
                local_path TEXT,
                postscript_name TEXT,
                is_downloaded INTEGER NOT NULL DEFAULT 0,
                updated_at REAL NOT NULL
            );

            CREATE TABLE IF NOT EXISTS surahs (
                id TEXT PRIMARY KEY,
                name_tr TEXT NOT NULL,
                name_ar TEXT NOT NULL,
                verse_count INTEGER NOT NULL,
                order_index INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS ayahs (
                id TEXT PRIMARY KEY,
                surah_id TEXT NOT NULL,
                ayah_no INTEGER NOT NULL,
                text TEXT NOT NULL,
                translation TEXT,
                page_no INTEGER,
                juz_no INTEGER
            );
            CREATE INDEX IF NOT EXISTS idx_ayah_surah ON ayahs (surah_id, ayah_no);

            CREATE TABLE IF NOT EXISTS juzs (
                id TEXT PRIMARY KEY,
                start_surah_id TEXT NOT NULL,
                start_ayah_no INTEGER NOT NULL,
                end_surah_id TEXT,
                end_ayah_no INTEGER
            );
            """,
            database: database
        )
    }

    private func openDatabase() throws -> OpaquePointer? {
        var database: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(databaseURL.path, &database, flags, nil) == SQLITE_OK else {
            if database != nil {
                sqlite3_close(database)
            }
            throw QuranSyncError.invalidResponse
        }

        return database
    }

    private func execute(_ sql: String, database: OpaquePointer?) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw QuranSyncError.invalidResponse
        }
    }

    private func bindText(_ value: String, index: Int32, statement: OpaquePointer?) {
        sqlite3_bind_text(statement, index, value, -1, sqliteTransientDestructor)
    }

    private func bindOptionalText(_ value: String?, index: Int32, statement: OpaquePointer?) {
        if let value {
            bindText(value, index: index, statement: statement)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }

    private func bindOptionalInt(_ value: Int?, index: Int32, statement: OpaquePointer?) {
        if let value {
            sqlite3_bind_int(statement, index, Int32(value))
        } else {
            sqlite3_bind_null(statement, index)
        }
    }

    private func readString(_ statement: OpaquePointer?, column: Int32) -> String? {
        guard let pointer = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: pointer)
    }
}

actor QuranFontRegistry {
    static let shared = QuranFontRegistry()

    private let fontDirectoryURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        fontDirectoryURL = appSupport.appendingPathComponent("Fonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: fontDirectoryURL, withIntermediateDirectories: true)
    }

    func installFont(_ font: QuranFont) async throws -> (localPath: String, postScriptName: String?) {
        guard let url = font.downloadURL else {
            throw QuranSyncError.fontDownloadURLMissing
        }

        try FileManager.default.createDirectory(at: fontDirectoryURL, withIntermediateDirectories: true)

        let (tempURL, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw QuranSyncError.invalidResponse
        }

        let fileExtension: String
        if url.pathExtension.isEmpty {
            fileExtension = "ttf"
        } else {
            fileExtension = url.pathExtension
        }

        let safeName = font.id.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "-", options: .regularExpression)
        let targetURL = fontDirectoryURL.appendingPathComponent("\(safeName).\(fileExtension)")

        if FileManager.default.fileExists(atPath: targetURL.path) {
            try? FileManager.default.removeItem(at: targetURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: targetURL)

        let postScriptName = try registerFontIfNeeded(at: targetURL)
        return (targetURL.path, postScriptName)
    }

    func registerCachedFontIfPossible(localPath: String) {
        let url = URL(fileURLWithPath: localPath)
        _ = try? registerFontIfNeeded(at: url)
    }

    private func registerFontIfNeeded(at url: URL) throws -> String? {
        var errorRef: Unmanaged<CFError>?
        let didRegister = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
        if !didRegister, let error = errorRef?.takeRetainedValue() as Error? {
            let nsError = error as NSError
            let alreadyRegisteredCode = 105
            if nsError.domain != kCTFontManagerErrorDomain as String || nsError.code != alreadyRegisteredCode {
                throw error
            }
        }

        if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
           let descriptor = descriptors.first,
           let postScriptName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String {
            return postScriptName
        }

        return nil
    }
}

actor QuranSyncService {
    static let shared = QuranSyncService()

    private let apiClient = QuranAPIClient()
    private let cacheStore = QuranCacheStore.shared
    private let fontRegistry = QuranFontRegistry.shared

    func loadCachedFonts() async -> [QuranFont] {
        (try? await cacheStore.loadFonts()) ?? []
    }

    func loadCachedSurahs() async -> [QuranSurah] {
        (try? await cacheStore.loadSurahs()) ?? []
    }

    func loadCachedJuzs() async -> [QuranJuz] {
        (try? await cacheStore.loadJuzs()) ?? []
    }

    func registerCachedFonts() async {
        let cached = (try? await cacheStore.loadFonts()) ?? []
        for font in cached where font.isDownloaded {
            if let localPath = font.localPath {
                await fontRegistry.registerCachedFontIfPossible(localPath: localPath)
            }
        }
    }

    func syncFonts() async throws -> [QuranFont] {
        do {
            let remote = try await apiClient.fetchFonts()
            let cached = (try? await cacheStore.loadFonts()) ?? []
            let merged = mergeFonts(remote: remote, cached: cached)
            try await cacheStore.saveFonts(merged)
            return merged
        } catch {
            let cached = (try? await cacheStore.loadFonts()) ?? []
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    func installFont(id: String) async throws -> QuranFont {
        var fonts = (try? await cacheStore.loadFonts()) ?? []
        guard let index = fonts.firstIndex(where: { $0.id == id }) else {
            throw QuranSyncError.fontNotFound
        }

        var font = fonts[index]
        let installed = try await fontRegistry.installFont(font)
        font.localPath = installed.localPath
        if let postScriptName = installed.postScriptName, !postScriptName.isEmpty {
            font.postScriptName = postScriptName
        }
        font.isDownloaded = true

        fonts[index] = font
        try await cacheStore.saveFonts(fonts)
        return font
    }

    func syncSurahs() async throws -> [QuranSurah] {
        do {
            let surahs = try await apiClient.fetchSurahs()
            try await cacheStore.saveSurahs(surahs)
            return surahs
        } catch {
            let cached = (try? await cacheStore.loadSurahs()) ?? []
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    func syncJuzs() async throws -> [QuranJuz] {
        do {
            let juzs = try await apiClient.fetchJuzs()
            try await cacheStore.saveJuzs(juzs)
            return juzs
        } catch {
            let cached = (try? await cacheStore.loadJuzs()) ?? []
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    func ayahs(for surahID: String, forceRefresh: Bool = false) async throws -> [QuranAyah] {
        if !forceRefresh {
            let cached = (try? await cacheStore.loadAyahs(surahID: surahID)) ?? []
            if !cached.isEmpty {
                return cached
            }
        }

        do {
            let remote = try await apiClient.fetchAyahs(surahID: surahID)
            try await cacheStore.saveAyahs(remote, surahID: surahID)
            return remote
        } catch {
            let cached = (try? await cacheStore.loadAyahs(surahID: surahID)) ?? []
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    private func mergeFonts(remote: [QuranFont], cached: [QuranFont]) -> [QuranFont] {
        let cachedByID = Dictionary(uniqueKeysWithValues: cached.map { ($0.id, $0) })

        var merged: [QuranFont] = []
        merged.reserveCapacity(remote.count)

        for remoteFont in remote {
            if let cachedFont = cachedByID[remoteFont.id] {
                merged.append(
                    QuranFont(
                        id: remoteFont.id,
                        displayName: remoteFont.displayName,
                        style: remoteFont.style ?? cachedFont.style,
                        downloadURL: remoteFont.downloadURL ?? cachedFont.downloadURL,
                        localPath: cachedFont.localPath,
                        postScriptName: cachedFont.postScriptName ?? remoteFont.postScriptName,
                        isDownloaded: cachedFont.isDownloaded
                    )
                )
            } else {
                merged.append(remoteFont)
            }
        }

        return merged.sorted {
            normalizedNameKey($0.displayName) < normalizedNameKey($1.displayName)
        }
    }

    private func normalizedNameKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

nonisolated(unsafe) private let sqliteTransientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
