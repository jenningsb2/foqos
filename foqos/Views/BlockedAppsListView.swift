import SwiftUI
import FamilyControls

struct BlockedAppsListView: View {
    @Environment(\.modelContext) private var context
    
    @State private var blockActivitySelection: BlockedActivitySelection?
    @State private var activitySelection = FamilyActivitySelection()
        
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $activitySelection)
        }
        .onChange(of: activitySelection) { oldValue, newValue in
            updateBlockedActivitySelection(newValue: newValue)
        }.onAppear() {
            loadBlockedActivitySelection()
        }
    }
    
    private func loadBlockedActivitySelection() {
        blockActivitySelection = BlockedActivitySelection.shared(in: context)
        if let val = blockActivitySelection?.selectedActivity {
            activitySelection = val
        }
    }
    
    private func updateBlockedActivitySelection(newValue: FamilyActivitySelection) {
        BlockedActivitySelection.updateShared(in: context, with: newValue)
    }
        
}

#Preview {
    BlockedAppsListView()
        .environmentObject(AppBlocker())
}
