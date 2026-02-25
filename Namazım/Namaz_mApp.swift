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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(notificationManager)
                .environmentObject(locationManager)
                .onAppear {
                    notificationManager.configureIfNeeded()
                    locationManager.configureIfNeeded()
                }
                .task {
                    await notificationManager.refreshAuthorizationStatus()
                    await notificationManager.rescheduleAll(using: appState)
                    locationManager.refreshAuthorizationStatus()
                    if locationManager.isAuthorized {
                        locationManager.requestSingleLocation()
                    }
                }
                .onChange(of: appState.notificationFingerprint) { _, _ in
                    Task {
                        await notificationManager.rescheduleAll(using: appState)
                    }
                }
                .onChange(of: appState.hasCompletedOnboarding) { _, completed in
                    guard completed else { return }
                    Task {
                        await notificationManager.refreshAuthorizationStatus()
                        await notificationManager.rescheduleAll(using: appState)
                    }
                    if locationManager.isAuthorized {
                        locationManager.requestSingleLocation()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await notificationManager.refreshAuthorizationStatus()
                        await notificationManager.rescheduleAll(using: appState)
                    }
                    locationManager.refreshAuthorizationStatus()
                    if locationManager.isAuthorized {
                        locationManager.requestSingleLocation()
                    }
                }
        }
    }
}
