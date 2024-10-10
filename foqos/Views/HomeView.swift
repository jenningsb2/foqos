import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var appBlocker: AppBlocker
    @StateObject private var nfcScanner = NFCScanner()
    
    @State var activitySelection = FamilyActivitySelection()
    @State private var isBlockedListPresented = false
    @State private var blockActivitySelection: BlockedActivitySelection?
    
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
                            isBlockedListPresented = true
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
                startBlocking()
            }
        }.padding(.horizontal, 20)
            .familyActivityPicker(isPresented: $isBlockedListPresented,
                                  selection: $activitySelection)
            .onChange(of: activitySelection) { _, newSelection in
                updateBlockedActivitySelection(newValue: activitySelection)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: nfcScanner.scannedNFCTag) { _, newValue in
                // TODO: do something with the newValue
            }
            .onAppear {
                loadApp()
            }
    }
    
    private func startBlocking() {
        nfcScanner.scan()
        print("Blocking now...")
        appBlocker.activateRestrictions(selection: activitySelection)
    }
    
    private func loadApp() {
        appBlocker.requestAuthorization()
        loadBlockedActivitySelection()
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
    HomeView()
        .environmentObject(AppBlocker())
}

