import SwiftUI
import FamilyControls
import SwiftData

struct BlockedProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // If profile is nil, we're creating a new profile
    var profile: BlockedProfiles?
    
    @State private var name: String = ""
    @State private var selectedActivity = FamilyActivitySelection()
    @State private var showingActivityPicker = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var isEditing: Bool {
        profile != nil
    }
    
    init(profile: BlockedProfiles? = nil) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _selectedActivity = State(initialValue: profile?.selectedActivity ?? FamilyActivitySelection())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Details") {
                    TextField("Profile Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Button(action: {
                        showingActivityPicker = true
                    }) {
                        HStack {
                            Text("Select Apps & Websites")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                
                Section("Selected Restrictions") {
                    Text("Apps & Websites selected")
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Update" : "Create") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .familyActivityPicker(
                isPresented: $showingActivityPicker,
                selection: $selectedActivity
            )
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func saveProfile() {
        do {
            if let existingProfile = profile {
                // Update existing profile
                try BlockedProfiles.updateProfile(
                    existingProfile,
                    in: modelContext,
                    name: name,
                    selection: selectedActivity
                )
            } else {
                // Create new profile
                let newProfile = BlockedProfiles(
                    name: name,
                    selectedActivity: selectedActivity
                )
                modelContext.insert(newProfile)
                try modelContext.save()
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// Preview provider for SwiftUI previews
#Preview {
    BlockedProfileView()
        .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
