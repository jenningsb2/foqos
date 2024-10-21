import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

class AppBlocker: ObservableObject {
    @Published var isBlocking = false
    @Published var isAuthorized = false
    
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("foqosAppRestrictions"))
    let center = DeviceActivityCenter()
    
    func activateRestrictions(selection: FamilyActivitySelection) {
        print("Starting restrictions...")
        
        
        let applicationTokens = selection.applicationTokens

        let blockedApps = Set(applicationTokens.map { Application(token: $0) })
        store.application.blockedApplications = blockedApps
        
        // Set up a DeviceActivitySchedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activity = DeviceActivityName("foqosDeviceActivity")
        let eventCenter = DeviceActivityCenter()
        do {
            try eventCenter.startMonitoring(activity, during: schedule)
        } catch {
            print("Error starting monitoring: \(error)")
        }
    }
    
    func deactivateRestrictions() {
        store.application.blockedApplications = nil
        center.stopMonitoring([DeviceActivityName("MyActivity")])
    }
    
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("Individual authorization successful")
                                
                isAuthorized = true
            } catch {
                print("Error requesting authorization: \(error)")
            }
        }
    }
}
