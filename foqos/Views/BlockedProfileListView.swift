import FamilyControls
import SwiftData
import SwiftUI

struct BlockedProfileListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [BlockedProfiles]
    @State private var showingCreateProfile = false
    @State private var profileToEdit: BlockedProfiles?

    var body: some View {
        NavigationStack {
            Group {
                if profiles.isEmpty {
                    EmptyView(
                        iconName: "person.crop.circle.badge.plus",
                        headingText:
                            "Group and switch between sessions effortlessly with customizable profiles"
                    )
                } else {
                    List {
                        ForEach(profiles) { profile in
                            ProfileRow(profile: profile)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    profileToEdit = profile
                                }
                        }
                        .onDelete(perform: deleteProfiles)
                    }
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateProfile = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create profile")
                                .bold()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateProfile) {
                BlockedProfileView()
            }
            .sheet(item: $profileToEdit) { profile in
                BlockedProfileView(profile: profile)
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = profiles[index]
            try? BlockedProfiles.deleteProfile(profile, in: modelContext)
        }
    }
}

#Preview {
    BlockedProfileListView()
        .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
