import Foundation
import UIKit

enum AppIconManagerError: LocalizedError {
    case notSupported
    case updateFailed

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Bu cihaz alternate app icon desteklemiyor."
        case .updateFailed:
            return "Uygulama ikonu değiştirilemedi."
        }
    }
}

@MainActor
enum AppIconManager {
    static var isSupported: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    static func currentIconChoice() -> AppIconChoice {
        AppIconChoice.resolve(from: UIApplication.shared.alternateIconName)
    }

    static func apply(choice: AppIconChoice) async throws {
        guard isSupported else {
            throw AppIconManagerError.notSupported
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(choice.iconName) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
