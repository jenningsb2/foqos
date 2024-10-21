import SwiftUI
import FamilyControls

struct HomeView: View {
    let AMZN_STORE_LINK = "https://amzn.to/4fbMuTM"
    
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject var appBlocker: AppBlocker
    @EnvironmentObject var donationManager: TipManager
    @EnvironmentObject var nfcScanner: NFCScanner
    
    @State private var isAppListPresent = false
    @State var activitySelection = FamilyActivitySelection()
    @State var activeSession: BlockedSession?
    @State var recentCompletedSessions: [BlockedSession]?
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var isBlocking: Bool {
        return activeSession?.isActive == true
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
                    ActionCard(
                        icon: "hand.raised.fill",
                        count: activitySelection.applicationTokens.count,
                        label: "Blocked Apps",
                        color: .red
                    ) {
                        isAppListPresent = true
                    }
                    ActionCard(
                        icon: "cart.fill",
                        count: nil,
                        label: "Purchase NFC tags",
                        color: .gray
                    ) {
                        if let url = URL(string: AMZN_STORE_LINK) {
                            openURL(url)
                        }
                    }
                }
                GridRow {
                    ActionCard(
                        icon: "heart.fill",
                        count: nil,
                        label: "Support us",
                        color: .green
                    ) {
                        donationManager.tip()
                    }
                }
            }
            
            InactiveBlockedSessionView(sessions: recentCompletedSessions ?? [])
            
            ActionButton(
                title: isBlocking ? "Scan to stop focus" : "Scan to start focus",
                backgroundColor: isBlocking ? Color.red : Color.indigo
            ) {
                nfcScanner.scan()
            }
        }.padding(.horizontal, 20)
            .familyActivityPicker(isPresented: $isAppListPresent,
                                  selection: $activitySelection)
            .onChange(of: activitySelection) { _, newSelection in
                updateBlockedActivitySelection(newValue: activitySelection)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: nfcScanner.scannedNFCTag) { _, newValue in
                toggleBlocking()
            }
            .onAppear {
                loadApp()
            }
            .onDisappear {
                unloadApp()
            }
    }
    
    private func toggleBlocking() {
        if isBlocking {
            stopBlocking()
        } else {
            startBlocking()
        }
        
        reloadApp()
    }
    
    private func startBlocking() {
        print("Starting app blocks...")
        
        appBlocker.activateRestrictions(selection: activitySelection)
        activeSession = BlockedSession
            .createSession(in: context, withTag: "test")
    }
    
    private func stopBlocking() {
        print("Stopping app blocks...")
        
        appBlocker.deactivateRestrictions()
        activeSession?.endSession()
        stopTimer()
    }
    
    private func loadApp() {
        appBlocker.requestAuthorization()
        
        activitySelection = BlockedActivitySelection
            .shared(in: context).selectedActivity
        activeSession = BlockedSession.mostRecentActiveSession(in: context)
        recentCompletedSessions = BlockedSession
            .recentInactiveSessions(in: context)
        startTimer()
    }
    
    private func unloadApp() {
        stopTimer()
    }
    
    private func reloadApp() {
        resetTimer()
        recentCompletedSessions = BlockedSession
            .recentInactiveSessions(in: context)
    }
    
    private func updateBlockedActivitySelection(
        newValue: FamilyActivitySelection
    ) {
        BlockedActivitySelection.updateSelection(in: context, with: newValue)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = activeSession?.startTime {
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

