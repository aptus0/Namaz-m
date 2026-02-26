import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case location
    case notifications
    case finish

    var title: String {
        switch self {
        case .welcome:
            return "Hoş Geldiniz"
        case .location:
            return "Konum Ayarı"
        case .notifications:
            return "Bildirim Ayarı"
        case .finish:
            return "Hazır"
        }
    }
}

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var locationManager: LocationManager

    @State private var step: OnboardingStep = .welcome
    @State private var showCityPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 6) {
                    ForEach(OnboardingStep.allCases, id: \.rawValue) { current in
                        Capsule(style: .continuous)
                            .fill(current.rawValue <= step.rawValue ? PremiumPalette.navy : Color.secondary.opacity(0.2))
                            .frame(height: 6)
                    }
                }
                .padding(.horizontal)

                Group {
                    switch step {
                    case .welcome:
                        welcomeContent
                    case .location:
                        locationContent
                    case .notifications:
                        notificationContent
                    case .finish:
                        finishContent
                    }
                }
                .animation(.easeInOut, value: step)

                Spacer()

                HStack(spacing: 12) {
                    if step != .welcome {
                        Button("Geri") {
                            previousStep()
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(primaryButtonTitle) {
                        handlePrimaryAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PremiumPalette.navy)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .premiumScreenBackground()
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerSheet { _ in
                if step == .location {
                    goToNextStep()
                }
            }
            .environmentObject(appState)
        }
        .onAppear {
            locationManager.configureIfNeeded()
            appState.applyDetectedCity(locationManager.resolvedCity)
        }
        .onChange(of: locationManager.resolvedCity) { _, city in
            appState.applyDetectedCity(city)
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .welcome:
            return "Devam"
        case .location:
            return locationPrimaryTitle
        case .notifications:
            return "Devam"
        case .finish:
            return "Uygulamayi Baslat"
        }
    }

    private var locationPrimaryTitle: String {
        if locationManager.isAuthorized {
            return "Devam"
        }
        if locationManager.isDenied {
            return "Il Secerek Devam"
        }
        return "Konum Iznini Ver"
    }

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Namaz vakitleri, hadis ve kibla takibini tek bir premium akista topladik.")
                .font(.title3.weight(.semibold))

            Text("Kurulum 1 dakikadan kisa surer. Konum ve bildirim iznini neden istedigimizi net sekilde gosterecegiz.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Label("Vakit yaklasirken hatirlatma", systemImage: "bell.badge")
                Label("Gunluk hadis bildirimi", systemImage: "book.closed")
                Label("Kibla pusulasi ve harita", systemImage: "location.north")
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
        .padding(.horizontal)
    }

    private var locationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Konumu sadece il tespiti ve kibla hesaplamasi icin kullaniyoruz.")
                .font(.headline)

            Text(locationManager.statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if locationManager.isLocating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Konum aliniyor...")
                        .font(.subheadline)
                }
            }

            if let city = locationManager.resolvedCity {
                Label("Tespit edilen il: \(city)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            HStack(spacing: 10) {
                Button("Konumu Yenile") {
                    locationManager.requestSingleLocation()
                }
                .buttonStyle(.bordered)
                .disabled(!locationManager.isAuthorized)

                Button("Ili Elle Sec") {
                    showCityPicker = true
                }
                .buttonStyle(.bordered)
            }

            if locationManager.isDenied {
                Button("Ayarlar'dan Konumu Ac") {
                    locationManager.openAppSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
        .padding(.horizontal)
    }

    private var notificationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bildirimleri vakit girisi, vakit oncesi ve gunluk hadis icin kullaniriz.")
                .font(.headline)

            Text(notificationManager.statusTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Bildirim Iznini Ver") {
                Task {
                    await notificationManager.requestAuthorizationIfNeeded()
                }
            }
            .buttonStyle(.bordered)

            Button("Bildirim Ayarlarini Ac") {
                notificationManager.openNotificationSettings()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
        .padding(.horizontal)
    }

    private var finishContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kurulum tamamlandi")
                .font(.title3.weight(.bold))

            HStack {
                Label("Secili il", systemImage: "mappin.and.ellipse")
                Spacer()
                Text(appState.selectedCity)
                    .fontWeight(.semibold)
            }

            HStack {
                Label("Konum", systemImage: "location")
                Spacer()
                Text(locationManager.statusDescription)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Label("Bildirim", systemImage: "bell")
                Spacer()
                Text(notificationManager.statusTitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle()
        .padding(.horizontal)
    }

    private func handlePrimaryAction() {
        switch step {
        case .welcome:
            goToNextStep()

        case .location:
            if locationManager.isAuthorized {
                goToNextStep()
            } else if locationManager.isDenied {
                showCityPicker = true
            } else {
                locationManager.requestWhenInUsePermission()
            }

        case .notifications:
            goToNextStep()

        case .finish:
            appState.completeOnboarding()
            Task {
                await notificationManager.refreshAuthorizationStatus()
                await notificationManager.rescheduleAll(using: appState)
            }
        }
    }

    private func previousStep() {
        guard let previous = OnboardingStep(rawValue: max(0, step.rawValue - 1)) else { return }
        step = previous
    }

    private func goToNextStep() {
        guard let next = OnboardingStep(rawValue: min(OnboardingStep.allCases.count - 1, step.rawValue + 1)) else { return }
        step = next
    }
}
