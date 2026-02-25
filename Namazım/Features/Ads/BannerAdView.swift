import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID: String

    func makeUIViewController(context: Context) -> BannerAdViewController {
        BannerAdViewController(adUnitID: adUnitID)
    }

    func updateUIViewController(_ uiViewController: BannerAdViewController, context: Context) {
        uiViewController.updateAdUnitID(adUnitID)
    }
}

final class BannerAdViewController: UIViewController {
    private var adUnitID: String
    private var bannerView: BannerView?

    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        loadBanner()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBannerSize()
    }

    func updateAdUnitID(_ adUnitID: String) {
        guard self.adUnitID != adUnitID else { return }
        self.adUnitID = adUnitID
        loadBanner()
    }

    private func loadBanner() {
        bannerView?.removeFromSuperview()

        let adSize = currentOrientationAnchoredAdaptiveBanner(width: max(view.bounds.width, 320))
        let banner = BannerView(adSize: adSize)
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.adUnitID = adUnitID
        banner.rootViewController = self
        banner.load(Request())

        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.topAnchor.constraint(equalTo: view.topAnchor),
            banner.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        bannerView = banner
    }

    private func updateBannerSize() {
        guard let bannerView else { return }
        let width = max(view.bounds.width, 320)
        let size = currentOrientationAnchoredAdaptiveBanner(width: width)
        if !isAdSizeEqualToSize(size1: bannerView.adSize, size2: size) {
            bannerView.adSize = size
        }
    }
}
