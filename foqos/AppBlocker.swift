import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

class AppBlocker: ObservableObject {
    @Published var isBlocking = false
    
    let store = ManagedSettingsStore()
    let center = DeviceActivityCenter()
    
    private var isAuthorized = false
    
    
    func activateRestrictions(selection: FamilyActivitySelection) {
        print("Starting restrictions...")
        
        var applications = store.application
        let applicationTokens = selection.applicationTokens
        applications.blockedApplications = Set(applicationTokens.map { Application(token: $0) })
        
        // Set up a DeviceActivitySchedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activity = DeviceActivityName("MyActivity")
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
                
                // If child authorization is also needed:
                try await AuthorizationCenter.shared.requestAuthorization(for: .child)
                print("Child authorization successful")
                
                isAuthorized = true
            } catch {
                print("Error requesting authorization: \(error)")
            }
        }
    }
}
