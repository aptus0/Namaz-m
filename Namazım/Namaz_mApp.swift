//
//  Namaz_mApp.swift
//  Namazım
//
//  Created by Samet on 25.02.2026.
//

import SwiftUI

@main
struct Namaz_mApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var adManager = AdManager()
    @State private var hasHandledFirstActivePhase = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(notificationManager)
                .environmentObject(locationManager)
                .environmentObject(adManager)
                .onAppear {
                    notificationManager.configureIfNeeded()
                    locationManager.configureIfNeeded()
                    adManager.configureIfNeeded()
                    if AppIconManager.isSupported {
                        let currentIcon = AppIconManager.currentIconChoice()
                        if appState.selectedAppIconChoice != currentIcon {
                            appState.selectedAppIconChoice = currentIcon
                        }
                    }
                }
                .task {
                    await notificationManager.refreshAuthorizationStatus()
                    await notificationManager.rescheduleAll(using: appState)
                    await appState.syncHadithCatalog()
                    await appState.syncQuranFonts()
                    await appState.syncQuranCatalog()
                    locationManager.refreshAuthorizationStatus()
                    if locationManager.isAuthorized {
                        locationManager.requestSingleLocation()
                    }
                    adManager.loadAllFormats()
                    WidgetSyncService.sync(using: appState)
                    await PrayerLiveActivityService.sync(using: appState)
                }
                .onChange(of: appState.notificationFingerprint) { _, _ in
                    Task {
                        await notificationManager.rescheduleAll(using: appState)
                        await PrayerLiveActivityService.sync(using: appState)
                    }
                    WidgetSyncService.sync(using: appState)
                }
                .onChange(of: appState.hasCompletedOnboarding) { _, completed in
                    guard completed else { return }
                    Task {
                        await notificationManager.refreshAuthorizationStatus()
                        await notificationManager.rescheduleAll(using: appState)
                        await appState.syncHadithCatalog()
                        await appState.syncQuranFonts()
                        await appState.syncQuranCatalog()
                        await PrayerLiveActivityService.sync(using: appState)
                    }
                    if locationManager.isAuthorized {
                        locationManager.requestSingleLocation()
                    }
                    adManager.loadAllFormats()
                    WidgetSyncService.sync(using: appState)
                }
                .onChange(of: appState.hadithSource) { _, _ in
                    Task {
                        await appState.syncHadithCatalog()
                    }
                }
                .onChange(of: appState.livePrayerActivityEnabled) { _, _ in
                    Task {
                        await PrayerLiveActivityService.sync(using: appState)
                    }
                }
                .onChange(of: appState.selectedCity) { _, _ in
                    WidgetSyncService.sync(using: appState)
                    Task {
                        await PrayerLiveActivityService.sync(using: appState)
                    }
                }
                .onChange(of: appState.language) { _, _ in
                    WidgetSyncService.sync(using: appState)
                    Task {
                        await PrayerLiveActivityService.sync(using: appState)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await notificationManager.refreshAuthorizationStatus()
                        await notificationManager.rescheduleAll(using: appState)
                        await PrayerLiveActivityService.sync(using: appState)
                    }
                    locationManager.refreshAuthorizationStatus()
                    if locationManager.isAuthorized {
                        locationManager.requestSingleLocation()
                    }
                    if appState.hasCompletedOnboarding {
                        if hasHandledFirstActivePhase {
                            adManager.showAppOpenIfEligible()
                        } else {
                            hasHandledFirstActivePhase = true
                        }
                    }
                    WidgetSyncService.sync(using: appState)
                }
        }
    }
}
