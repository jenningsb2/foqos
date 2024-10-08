import SwiftUI
import FamilyControls

struct BlockedAppsListView: View {
    @State private var activitySelection = FamilyActivitySelection()
    @EnvironmentObject var appBlocker: AppBlocker
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $activitySelection)
                .navigationTitle("Select Apps to Block")
        }
        .onChange(of: activitySelection) { oldValue, newValue in
            appBlocker.updateSelection(newValue)
        }
    }
}
