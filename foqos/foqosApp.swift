//
//  foqosApp.swift
//  foqos
//
//  Created by Ali Waseem on 2024-10-06.
//

import SwiftData
import SwiftUI

@main
struct foqosApp: App {
    @StateObject private var appBlocker = AppBlocker()
    @StateObject private var donationManager = TipManager()
    @StateObject private var nfcScanner = NFCScanner()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appBlocker)
                .environmentObject(donationManager)
                .environmentObject(nfcScanner)
                .onOpenURL { url in
                    handleUniversalLink(url)
                }
        }
        .modelContainer(
            for: [
                BlockedActivitySelection.self,
                BlockedProfileSession.self,
                BlockedProfiles.self,
            ]
        )
    }

    private func handleUniversalLink(_ url: URL) {
        // Parse and handle the URL
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard let path = components?.path else { return }

        // Use your app's navigation state to navigate
        // Example using @StateObject:
        switch path {
        case "/products":
            // Navigate to products
            break
        case "/profile":
            // Navigate to profile
            break
        default:
            break
        }
    }
}
