import SwiftUI

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                }
                
                Section(header: Text("About")) {
                    Text("NFC App Blocker v1.0")
                    Text("Created by Your Name")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
