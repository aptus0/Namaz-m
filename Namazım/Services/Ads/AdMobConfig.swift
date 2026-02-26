import Foundation

enum AdMobConfig {
    static let applicationID = "ca-app-pub-3321006469806168~2800259705"

    private enum TestUnit {
        static let banner = "ca-app-pub-3940256099942544/2435281174"
        static let interstitial = "ca-app-pub-3940256099942544/4411468910"
        static let rewarded = "ca-app-pub-3940256099942544/1712485313"
        static let appOpen = "ca-app-pub-3940256099942544/5575463023"
    }

    private enum InfoKey {
        static let banner = "GADBannerUnitID"
        static let interstitial = "GADInterstitialUnitID"
        static let rewarded = "GADRewardedUnitID"
        static let appOpen = "GADAppOpenUnitID"
    }

    static var bannerUnitID: String {
        productionAwareUnit(for: InfoKey.banner, fallback: "ca-app-pub-3321006469806168/6554983522", test: TestUnit.banner)
    }

    static var interstitialUnitID: String {
        productionAwareUnit(for: InfoKey.interstitial, fallback: "", test: TestUnit.interstitial)
    }

    static var rewardedUnitID: String {
        productionAwareUnit(for: InfoKey.rewarded, fallback: "", test: TestUnit.rewarded)
    }

    static var appOpenUnitID: String {
        productionAwareUnit(for: InfoKey.appOpen, fallback: "", test: TestUnit.appOpen)
    }

    private static func productionAwareUnit(for infoKey: String, fallback: String, test: String) -> String {
        #if DEBUG
        if let configured = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String, !configured.isEmpty {
            return configured
        }
        if !fallback.isEmpty {
            return fallback
        }
        return test
        #else
        if let configured = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String, !configured.isEmpty {
            return configured
        }
        if !fallback.isEmpty {
            return fallback
        }
        assertionFailure("Missing production AdMob unit for key: \(infoKey).")
        return test
        #endif
    }
}

enum AdPlacement: String {
    case calendarDayDetail
    case hadithCollection
}
