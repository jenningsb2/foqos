import SwiftUI
import FamilyControls

struct ProfileRow: View {
    let profile: BlockedProfiles
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.name)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let previewProfile = BlockedProfiles(
        name: "⌛ School Hours",
        selectedActivity: FamilyActivitySelection(),
        createdAt: Date(),
        updatedAt: Date().addingTimeInterval(-3600) // 1 hour ago
    )
    
    return ProfileRow(profile: previewProfile)
        .padding()
        .modelContainer(for: BlockedActivitySelection.self, inMemory: true)
}
