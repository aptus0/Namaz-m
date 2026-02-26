import Foundation

enum QuranSyncState: Equatable {
    case idle
    case syncing
    case synced(count: Int, date: Date)
    case failed(message: String)
}

enum QuranFontInstallState: Equatable {
    case notDownloaded
    case downloading
    case downloaded
    case failed(message: String)
}

struct QuranFont: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let style: String?
    let downloadURL: URL?
    var localPath: String?
    var postScriptName: String?
    var isDownloaded: Bool

    var isReadyForUse: Bool {
        isDownloaded && (postScriptName?.isEmpty == false)
    }

    var normalizedDisplayName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? id : trimmed
    }
}

struct QuranSurah: Identifiable, Codable, Hashable {
    let id: String
    let nameTr: String
    let nameAr: String
    let verseCount: Int
    let order: Int

    var title: String {
        if nameTr.isEmpty { return nameAr }
        if nameAr.isEmpty { return nameTr }
        return "\(nameTr) • \(nameAr)"
    }
}

struct QuranAyah: Identifiable, Codable, Hashable {
    let id: String
    let surahID: String
    let ayahNo: Int
    let text: String
    let translation: String?
    let pageNo: Int?
    let juzNo: Int?
}

struct QuranJuz: Identifiable, Codable, Hashable {
    let id: String
    let startSurahID: String
    let startAyahNo: Int
    let endSurahID: String?
    let endAyahNo: Int?
}
