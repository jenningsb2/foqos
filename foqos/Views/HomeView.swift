import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var appBlocker: AppBlocker
    @StateObject private var nfcScanner = NFCScanner()
    
    @State private var isAppListPresent = false
    @State var activitySelection = FamilyActivitySelection()
    @State var recentSession: BlockedSession?
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var isBlocking: Bool {
        return recentSession?.isActive == true
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Time in Focus")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                
                Text(timeString(from: elapsedTime))
                    .font(.system(size: 80))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }.padding(.top, 20)
            
            Grid(horizontalSpacing: 10, verticalSpacing: 16) {
                GridRow {
                    ActionCard(icon: "hand.raised.fill", count: 8, label: "Blocked Apps", color: .red) {
                        isAppListPresent = true
                    }
                    ActionCard(icon: "cart.fill", count: nil, label: "Purschase NFC tags", color: .gray) {
                        print("Buy tags")
                    }
                }
                GridRow {
                    ActionCard(icon: "heart.fill", count: nil, label: "Donate", color: .green) {
                        print("Thanks for the donation")
                    }
                }
            }
            
            Spacer()
            
            ActionButton(title: isBlocking ? "Scan to stop focus" : "Scan to start focus") {
                toggleBlocking()
            }
        }.padding(.horizontal, 20)
            .familyActivityPicker(isPresented: $isAppListPresent,
                                  selection: $activitySelection)
            .onChange(of: activitySelection) { _, newSelection in
                updateBlockedActivitySelection(newValue: activitySelection)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: nfcScanner.scannedNFCTag) { _, newValue in
                // TODO: call toggle blocking here
            }
            .onAppear {
                loadApp()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
    }
    
    private func toggleBlocking() {
        if isBlocking {
            stopBlocking()
        } else {
            startBlocking()
        }
        
        resetTimer()
    }

    private func startBlocking() {
        print("Starting app blocks...")
        
        appBlocker.activateRestrictions(selection: activitySelection)
        recentSession = BlockedSession.createSession(in: context, withTag: "test")
    }
    
    private func stopBlocking() {
        print("Stopping app blocks...")
        
        appBlocker.deactivateRestrictions()
        recentSession?.endSession()
        startTimer()
    }
    
    private func loadApp() {
        appBlocker.requestAuthorization()
        
        activitySelection = BlockedActivitySelection.shared(in: context).selectedActivity
        recentSession = BlockedSession.mostRecentActiveSession(in: context)
        stopTimer()
    }
    
    private func updateBlockedActivitySelection(
        newValue: FamilyActivitySelection
    ) {
        BlockedActivitySelection.updateSelection(in: context, with: newValue)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = recentSession?.startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        elapsedTime = 0
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppBlocker())
}

