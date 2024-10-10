import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var appBlocker: AppBlocker
    @StateObject private var nfcScanner = NFCScanner()
    
    @State private var isAppListPresent = false
    @State var activitySelection = FamilyActivitySelection()
    @State var blocking = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Time in Focus")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                
                Text("00:00:00")
                    .font(.system(size: 80))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }.padding(.top, 20)
            
            GroupBox {
                WeeklyBarChart()
            } label: {
                Text("Weekly focus time")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }.cornerRadius(10)
            
            GroupBox {
                Section {
                    MenuItem(
                        icon: "hand.raised.fill",
                        iconColor: .red,
                        title: "Apps to block",
                        subtitle: nil,
                        hasDisclosure: true,
                        action: {
                            isAppListPresent = true
                        }
                    )
                    MenuItem(
                        icon: "cart.fill",
                        iconColor: .gray,
                        title: "Purschase NFC tags",
                        subtitle: nil,
                        hasDisclosure: true,
                        action: { print("Airplane mode toggled") }
                    )
                    MenuItem(
                        icon: "heart.fill",
                        iconColor: .green,
                        title: "Donate",
                        subtitle: nil,
                        hasDisclosure: true,
                        action: { print("Airplane mode toggled") }
                    )
                }
            } label: {
                Text("Settings")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }.cornerRadius(10)
            
            Spacer()
            ActionButton(title: "Scan to focus") {
                toggleBlocking()
            }
        }.padding(.horizontal, 20)
            .familyActivityPicker(isPresented: $isAppListPresent,
                                  selection: $activitySelection)
            .onChange(of: activitySelection) { _, newSelection in
                updateBlockedActivitySelection(newValue: activitySelection)
            }
            .onChange(of: blocking) { _, newBlocking in
                updateBlockedActivityBlocking(newValue: newBlocking)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: nfcScanner.scannedNFCTag) { _, newValue in
                // TODO: call toggle blocking here
            }
            .onAppear {
                loadApp()
            }
    }
    
    private func toggleBlocking() {
        if blocking {
            stopBlocking()
            return
        }
        
        startBlocking()
    }

    private func startBlocking() {
        print("Starting app blocks...")
        
        appBlocker.activateRestrictions(selection: activitySelection)
        blocking = true
    }
    
    private func stopBlocking() {
        print("Stopping app blocks...")
        
        appBlocker.deactivateRestrictions()
        blocking = false
    }
    
    private func loadApp() {
        appBlocker.requestAuthorization()
        
        let blockActivitySelection = BlockedActivitySelection.shared(in: context)
        activitySelection = blockActivitySelection.selectedActivity
        blocking = blockActivitySelection.isBlocking
    }
    
    private func updateBlockedActivitySelection(
        newValue: FamilyActivitySelection
    ) {
        BlockedActivitySelection.updateSelection(in: context, with: newValue)
    }
    
    private func updateBlockedActivityBlocking(newValue: Bool) {
        BlockedActivitySelection.updateBlocking(in: context, with: newValue)
    }
       
}

#Preview {
    HomeView()
        .environmentObject(AppBlocker())
}

