import Foundation

enum AdMobConfig {
    static let applicationID = "ca-app-pub-3321006469806168~2800259705"

    // Production banner unit ID provided for Namazim.
    static let bannerUnitID = "ca-app-pub-3321006469806168/6554983522"

    // Until dedicated production units are created in AdMob, test IDs are used below.
    // Replace with your real unit IDs before release for each format.
    static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let rewardedUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let appOpenUnitID = "ca-app-pub-3940256099942544/5575463023"
}

enum AdPlacement: String {
    case calendarDayDetail
    case hadithCollection
}
