import FamilyControls
import SwiftData
import SwiftUI

struct HomeView: View {
    let AMZN_STORE_LINK = "https://amzn.to/4fbMuTM"

    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL

    @EnvironmentObject var appBlocker: AppBlocker
    @EnvironmentObject var donationManager: TipManager
    @EnvironmentObject var nfcScanner: NFCScanner

    // Profile management
    @Query(sort: \BlockedProfiles.updatedAt, order: .reverse) private var profiles: [BlockedProfiles]
    @State private var profileIndex = 0
    @State private var isProfileListPresent = false

    // Activity sessions
    @State private var isAppListPresent = false
    @State var activitySelection = FamilyActivitySelection()
    @State var activeSession: BlockedSession?
    @State var recentCompletedSessions: [BlockedSession]?

    // Timers
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    // Alerts
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Intro sheet
    @AppStorage("showIntroScreen") private var showIntroScreen = true

    var isBlocking: Bool {
        return activeSession?.isActive == true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let mostRecent = profiles[safe: profileIndex] {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Active profile")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                    
                    BlockedProfileSelector(
                        profile: mostRecent,
                        onSwipeLeft: {
                            incrementProfiles()
                        },
                        onSwipeRight: {
                            decrementProfiles()
                        }
                    )
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Time in Focus")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)

                Text(timeString(from: elapsedTime))
                    .font(.system(size: 80))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Grid(horizontalSpacing: 10, verticalSpacing: 16) {
                GridRow {
                    ActionCard(
                        icon: "person.crop.circle.fill",
                        count: nil,
                        label: "Profiles",
                        color: .purple
                    ) {
                        isProfileListPresent = true
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
                title: isBlocking
                    ? "Scan to stop focus" : "Scan to start focus",
                backgroundColor: isBlocking ? Color.red : Color.indigo
            ) {
                scanButtonPress()
            }
        }.padding(.horizontal, 20)
            .sheet(isPresented: $isProfileListPresent) {
                BlockedProfileListView()
            }
            .familyActivityPicker(
                isPresented: $isAppListPresent,
                selection: $activitySelection
            )
            .onChange(of: activitySelection) { _, newSelection in
                updateBlockedActivitySelection(newValue: activitySelection)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: nfcScanner.scannedNFCTag) { _, newValue in
                if let nfcResults = newValue {
                    toggleBlocking(results: nfcResults)
                }
            }
            .onChange(of: appBlocker.isAuthorized) { _, newValue in
                if newValue {
                    showIntroScreen = false
                } else {
                    showIntroScreen = true
                }
            }
            .onAppear {
                loadApp()
            }
            .onDisappear {
                unloadApp()
            }.sheet(isPresented: $showIntroScreen) {
                IntroView {
                    appBlocker.requestAuthorization()
                }.interactiveDismissDisabled()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { dismissAlert() }
            } message: {
                Text(alertMessage)
            }
    }
    
    private func incrementProfiles() {
        guard !profiles.isEmpty else { return }
        
        profileIndex = (profileIndex + 1) % profiles.count
    }

    private func decrementProfiles() {
        guard !profiles.isEmpty else { return }
        
        profileIndex = (profileIndex - 1 + profiles.count) % profiles.count
    }

    private func scanButtonPress() {
        nfcScanner.scan()
    }

    private func toggleBlocking(results: NFCResult) {
        print(
            "Toggling block for scanned tag \(results.id) on \(results.DateScanned)"
        )

        let tag = results.id
        if isBlocking {
            stopBlocking(tag: tag)
        } else {
            startBlocking(tag: tag)
        }

        reloadApp()
    }

    private func startBlocking(tag: String) {
        print("Starting app blocks...")

        appBlocker.activateRestrictions(selection: activitySelection)
        activeSession =
            BlockedSession
            .createSession(in: context, withTag: tag)
        startTimer()
    }

    private func stopBlocking(tag: String) {
        print("Stopping app blocks...")

        guard let session = activeSession else {
            print(
                "No active session found, calling stop blocking with no session"
            )
            return
        }

        if session.tag != tag {
            print("session tag: \(session.tag) does not match with tag: \(tag)")
            showErrorAlert(
                message: "You must scan the original tag to stop focus")
            return
        }

        appBlocker.deactivateRestrictions()
        activeSession?.endSession()
        stopTimer()
    }

    private func loadApp() {
        activitySelection =
            BlockedActivitySelection
            .shared(in: context).selectedActivity
        activeSession = BlockedSession.mostRecentActiveSession(in: context)
        recentCompletedSessions =
            BlockedSession
            .recentInactiveSessions(in: context)

        if activeSession?.isActive == true {
            startTimer()
        }
    }

    private func unloadApp() {
        stopTimer()
    }

    private func reloadApp() {
        resetTimer()
        recentCompletedSessions =
            BlockedSession
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

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    private func showErrorAlert(message: String) {
        self.showAlert(title: "Whoops", message: message)
    }

    private func dismissAlert() {
        showingAlert = false
        alertTitle = ""
        alertMessage = ""
    }
}

#Preview {
    HomeView()
        .environmentObject(AppBlocker())
        .environmentObject(TipManager())
        .environmentObject(NFCScanner())
        .defaultAppStorage(UserDefaults(suiteName: "preview")!)
        .onAppear {
            UserDefaults(suiteName: "preview")!.set(
                false, forKey: "showIntroScreen")
        }
}
