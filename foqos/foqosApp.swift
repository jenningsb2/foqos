//
//  foqosApp.swift
//  foqos
//
//  Created by Ali Waseem on 2024-10-06.
//

import SwiftUI
import SwiftData

@main
struct foqosApp: App {
    @StateObject private var appBlocker = AppBlocker()
    @StateObject private var donationManager = TipManager()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appBlocker)
                .environmentObject(donationManager)
        }
        .modelContainer(for: [BlockedActivitySelection.self, BlockedSession.self])
    }
}
