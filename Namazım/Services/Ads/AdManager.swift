import Foundation
import Combine
import UIKit
import GoogleMobileAds

@MainActor
final class AdManager: NSObject, ObservableObject {
    @Published private(set) var isSDKReady = false
    @Published private(set) var adFreeUntil: Date?

    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    private var appOpen: AppOpenAd?

    private var isConfigured = false
    private static let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    private static let isDebugBuild: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    private static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()

    private enum Keys {
        static let adFreeUntil = "ads.adFreeUntil"
        static let interstitialDay = "ads.interstitialDay"
        static let interstitialCount = "ads.interstitialCount"
        static let appOpenLastDay = "ads.appOpenLastDay"
    }

    private var adsRuntimeEnabled: Bool {
        !Self.isPreview && !Self.isDebugBuild && !Self.isSimulator
    }

    func configureIfNeeded() {
        guard !isConfigured else { return }
        guard adsRuntimeEnabled else { return }
        isConfigured = true

        restorePersistedState()

        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSDKReady = true
                self.loadAllFormats()
            }
        }
    }

    var isAdFreeActive: Bool {
        guard let adFreeUntil else { return false }
        return adFreeUntil > Date()
    }

    var shouldShowBannerAds: Bool {
        adsRuntimeEnabled && isSDKReady && !isAdFreeActive
    }

    func loadAllFormats() {
        guard adsRuntimeEnabled, isSDKReady, !isAdFreeActive else { return }
        loadInterstitial()
        loadRewarded()
        loadAppOpen()
    }

    func showInterstitialIfEligible(for placement: AdPlacement) {
        guard adsRuntimeEnabled else { return }
        guard shouldShowInterstitial else { return }
        guard let rootVC = Self.topViewController(), let interstitial else {
            loadInterstitial()
            return
        }

        interstitial.present(from: rootVC)
        incrementInterstitialCount()
        print("Interstitial shown for placement: \(placement.rawValue)")
    }

    func showRewardedUnlock() {
        guard adsRuntimeEnabled else { return }
        guard isSDKReady else { return }
        guard let rootVC = Self.topViewController(), let rewarded else {
            loadRewarded()
            return
        }

        rewarded.present(from: rootVC) { [weak self] in
            Task { @MainActor in
                self?.unlockAdFree24Hours()
            }
        }
    }

    func showAppOpenIfEligible() {
        guard adsRuntimeEnabled else { return }
        guard shouldShowAppOpen else { return }
        guard let rootVC = Self.topViewController(), let appOpen else {
            loadAppOpen()
            return
        }

        appOpen.present(from: rootVC)
        UserDefaults.standard.set(Self.currentDayKey(), forKey: Keys.appOpenLastDay)
    }

    private var shouldShowInterstitial: Bool {
        guard adsRuntimeEnabled, isSDKReady, !isAdFreeActive else { return false }
        refreshDailyInterstitialCountersIfNeeded()
        let count = UserDefaults.standard.integer(forKey: Keys.interstitialCount)
        return count < 2
    }

    private var shouldShowAppOpen: Bool {
        guard adsRuntimeEnabled, isSDKReady, !isAdFreeActive else { return false }
        let lastDay = UserDefaults.standard.string(forKey: Keys.appOpenLastDay)
        return lastDay != Self.currentDayKey()
    }

    private func loadInterstitial() {
        guard adsRuntimeEnabled, !isAdFreeActive else { return }

        let request = Request()
        InterstitialAd.load(with: AdMobConfig.interstitialUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    print("Interstitial load error: \(error.localizedDescription)")
                    return
                }

                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
            }
        }
    }

    private func loadRewarded() {
        guard adsRuntimeEnabled, !isAdFreeActive else { return }

        let request = Request()
        RewardedAd.load(with: AdMobConfig.rewardedUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    print("Rewarded load error: \(error.localizedDescription)")
                    return
                }

                self.rewarded = ad
                self.rewarded?.fullScreenContentDelegate = self
            }
        }
    }

    private func loadAppOpen() {
        guard adsRuntimeEnabled, !isAdFreeActive else { return }

        let request = Request()
        AppOpenAd.load(with: AdMobConfig.appOpenUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    print("AppOpen load error: \(error.localizedDescription)")
                    return
                }

                self.appOpen = ad
                self.appOpen?.fullScreenContentDelegate = self
            }
        }
    }

    private func unlockAdFree24Hours() {
        let expiry = Date().addingTimeInterval(24 * 60 * 60)
        adFreeUntil = expiry
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: Keys.adFreeUntil)
        interstitial = nil
        appOpen = nil
    }

    private func restorePersistedState() {
        let raw = UserDefaults.standard.double(forKey: Keys.adFreeUntil)
        if raw > 0 {
            let savedDate = Date(timeIntervalSince1970: raw)
            if savedDate > Date() {
                adFreeUntil = savedDate
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.adFreeUntil)
            }
        }

        refreshDailyInterstitialCountersIfNeeded()
    }

    private func refreshDailyInterstitialCountersIfNeeded() {
        let storedDay = UserDefaults.standard.string(forKey: Keys.interstitialDay)
        let today = Self.currentDayKey()
        if storedDay != today {
            UserDefaults.standard.set(today, forKey: Keys.interstitialDay)
            UserDefaults.standard.set(0, forKey: Keys.interstitialCount)
        }
    }

    private func incrementInterstitialCount() {
        refreshDailyInterstitialCountersIfNeeded()
        let current = UserDefaults.standard.integer(forKey: Keys.interstitialCount)
        UserDefaults.standard.set(current + 1, forKey: Keys.interstitialCount)
    }

    private static func currentDayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController? = {
            if let base { return base }
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            let keyWindow = scene?.windows.first { $0.isKeyWindow }
            return keyWindow?.rootViewController
        }()

        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }

        return root
    }
}



extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            if ad === self.interstitial {
                self.interstitial = nil
                self.loadInterstitial()
            }

            if ad === self.rewarded {
                self.rewarded = nil
                self.loadRewarded()
            }

            if ad === self.appOpen {
                self.appOpen = nil
                self.loadAppOpen()
            }
        }
    }

    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            print("Full screen ad present error: \(error.localizedDescription)")
        }
    }
}
