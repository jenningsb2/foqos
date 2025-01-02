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
                .onOpenURL() { url in
                    handleUniversalLink(url)
                }
                .environmentObject(appBlocker)
                .environmentObject(donationManager)
                .environmentObject(nfcScanner)
        }
        .modelContainer(
            for: [
                BlockedProfileSession.self,
                BlockedProfiles.self,
            ]
        )
    }
    
    
    private func handleUniversalLink(_ url: URL) {
        print("Universal link received:", url.absoluteString) // Add this
        
        // Parse and handle the URL
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard let path = components?.path else { return }

        // Use your app's navigation state to navigate
        // Example using @StateObject:
        print("Path:", path) // Add this
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
