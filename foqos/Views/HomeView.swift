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
    @EnvironmentObject var navigationManager: NavigationManager

    // Profile management
    @Query(sort: \BlockedProfiles.updatedAt, order: .reverse) private
        var profiles: [BlockedProfiles]
    @State private var activeProfile: BlockedProfiles? = nil
    @State private var profileIndex = 0
    @State private var isProfileListPresent = false
    @State private var showActiveProfileView = false

    // Activity sessions
    @Query(sort: \BlockedProfileSession.startTime, order: .reverse) private
        var sessions: [BlockedProfileSession]
    @Query(
        filter: #Predicate<BlockedProfileSession> { $0.endTime != nil },
        sort: \BlockedProfileSession.endTime,
        order: .reverse
    ) private var recentCompletedSessions: [BlockedProfileSession]

    @State var activeSession: BlockedProfileSession?

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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("Time in Focus")

                    Text(timeString(from: elapsedTime))
                        .font(.system(size: 80))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("Weekly Usage")

                    BlockedSessionsChart(
                        sessions: recentCompletedSessions)
                }

                if let mostRecent = activeProfile {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle("Active Profile")

                        BlockedProfileSelector(
                            profile: mostRecent,
                            isActive: activeProfile?.id == activeSession?.blockedProfile.id,
                            onSwipeLeft: {
                                incrementProfiles()
                            },
                            onSwipeRight: {
                                decrementProfiles()
                            },
                            onTap: {
                                showActiveProfileView = true
                            },
                            onLongPress: {
                                scanButtonPress()
                            }
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("Manage")

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
                                icon: "wave.3.right.circle.fill",
                                count: nil,
                                label: isBlocking
                                    ? "Stop session" : "Start session",
                                color: isBlocking ? .red : .green
                            ) {
                                scanButtonPress()
                            }
                            ActionCard(
                                icon: "heart.fill",
                                count: nil,
                                label: "Support us",
                                color: .pink
                            ) {
                                donationManager.tip()
                            }
                        }
                    }
                }

                Spacer()

                VersionFooter()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 1)
        .padding(.horizontal, 20)
        .sheet(
            isPresented: $isProfileListPresent,
            onDismiss: {
                if profileIndex >= profiles.count {
                    profileIndex = max(profiles.count - 1, 0)
                }

                activeProfile = profiles[safe: profileIndex]
            }
        ) {
            BlockedProfileListView()
        }
        .frame(
            minWidth: 0, maxWidth: .infinity, minHeight: 0,
            maxHeight: .infinity, alignment: .topLeading
        )
        .onChange(of: profileIndex) { _, newValue in
            activeProfile = profiles[safe: profileIndex]
        }
        .onChange(of: navigationManager.profileId) { _, newValue in
            if let profileId = newValue {
                toggleSessionFromDeeplink(profileId)
            }
        }
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
        }.sheet(isPresented: $showActiveProfileView) {
            BlockedProfileView(profile: activeProfile)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { dismissAlert() }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func toggleSessionFromDeeplink(_ profileId: String) {
        guard let profileUUID = UUID(uuidString: profileId) else {
            showErrorAlert(message: "Failed to parse profile in tag")
            return
        }
        
        do {
            guard let profile = try BlockedProfiles.findProfile(
                byID: profileUUID,
                in: context
            ) else {
                showErrorAlert(message: "Failed to find a profile stored locally that matches the tag")
                return
            }
            
            let url = BlockedProfiles.getProfileDeepLink(profile)
            let nfcResults = nfcScanner.resultFromURL(url)
            
            toggleBlocking(results: nfcResults)
            navigationManager.clearProfileId()
        } catch {
            showErrorAlert(message: "Something went wrong fetching profile")
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

        let tag = results.url ?? results.id
        if isBlocking {
            stopBlocking(tag: tag)
        } else {
            startBlocking(tag: tag)
        }

        reloadApp()
    }

    private func startBlocking(tag: String) {
        if let definedProfile = activeProfile {
            appBlocker
                .activateRestrictions(
                    selection: definedProfile.selectedActivity
                )
            activeSession =
                BlockedProfileSession
                .createSession(
                    in: context,
                    withTag: tag,
                    withProfile: definedProfile
                )
            startTimer()
        }
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
        session.endSession()
        
        activeSession = nil
        stopTimer()
    }

    private func loadApp() {
        activeProfile = profiles[safe: profileIndex]

        activeSession =
            BlockedProfileSession
            .mostRecentActiveSession(in: context)

        if activeSession?.isActive == true {
            startTimer()
        }
    }

    private func unloadApp() {
        stopTimer()
    }

    private func reloadApp() {
        resetTimer()
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
