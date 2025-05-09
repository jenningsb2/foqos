import FamilyControls
import SwiftData
import SwiftUI

struct HomeView: View {
    let AMZN_STORE_LINK = "https://amzn.to/4fbMuTM"

    @Environment(\.modelContext) private var context
    @Environment(\.openURL) var openURL

    @EnvironmentObject var requestAuthorizer: RequestAuthorizer
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var donationManager: TipManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var ratingManager: RatingManager

    // Profile management
    @Query(sort: \BlockedProfiles.createdAt, order: .reverse) private
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

    // Alerts
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Intro sheet
    @AppStorage("showIntroScreen") private var showIntroScreen = true

    // UI States
    @State private var isRefreshing = false
    @State private var opacityValue = 1.0

    var activeProfileStrategy: BlockingStrategy {
        if let activeStrategyId = strategyManager.activeSession?.blockedProfile
            .blockingStrategyId
        {
            return strategyManager.getStrategy(id: activeStrategyId)
        }

        return
            strategyManager
            .getStrategy(
                id: activeProfile?.blockingStrategyId
                    ?? NFCBlockingStrategy
                    .id
            )
    }

    var isBlocking: Bool {
        return strategyManager.isBlocking
    }

    var activeSessionProfileId: UUID? {
        return strategyManager.activeSession?.blockedProfile.id
    }

    var isBreakAvailable: Bool {
        return strategyManager.isBreakAvailable
    }

    var isBreakActive: Bool {
        return strategyManager.isBreakActive
    }

    var sessionStatusStr: String {
        if let activeSession = strategyManager.activeSession {
            return "Stop " + activeSession.blockedProfile.name
        }

        let sessionName = activeProfile?.name ?? "Sesssion"
        return "Start " + sessionName
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            RefreshControl(isRefreshing: $isRefreshing) {
                loadApp()
            }

            VStack(alignment: .leading, spacing: 30) {
                Text("Foqos")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)

                if profiles.isEmpty {
                    Welcome(onTap: {
                        showActiveProfileView = true
                    })
                    .padding(.horizontal, 16)
                }

                if !profiles.isEmpty {
                    BlockedSessionsHabitTracker(
                        sessions: recentCompletedSessions
                    )
                    .padding(.horizontal, 16)

                    BlockedProfileCarousel(
                        profiles: profiles,
                        isBlocking: isBlocking,
                        isBreakAvailable: isBreakAvailable,
                        isBreakActive: isBreakActive,
                        activeSessionProfileId: activeSessionProfileId,
                        elapsedTime: strategyManager.elapsedTime,
                        onStartTapped: { profile in
                            activeProfile = profile
                            strategyButtonPress()
                        },
                        onStopTapped: { profile in
                            activeProfile = profile
                            strategyButtonPress()
                        },
                        onEditTapped: { profile in
                            activeProfile = profile
                            showActiveProfileView = true
                        },
                        onBreakTapped: { _ in
                            strategyManager.toggleBreak()
                        }
                    )
                }

                ManageSection(actions: [
                    ManageAction(
                        icon: "person.crop.circle.fill",
                        label: "Profiles",
                        color: .purple,
                        action: { isProfileListPresent = true }
                    ),
                    ManageAction(
                        icon: "cart.fill",
                        label: "Purchase NFC tags",
                        color: .gray,
                        action: {
                            if let url = URL(string: AMZN_STORE_LINK) {
                                openURL(url)
                            }
                        }
                    ),
                    ManageAction(
                        icon: "heart.fill",
                        label: "Support us",
                        color: .pink,
                        action: { donationManager.tip() }
                    ),
                ])
                .padding(.horizontal, 16)

                VersionFooter()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 1)
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
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .onChange(of: profileIndex) { _, newValue in
            activeProfile = profiles[safe: profileIndex]
        }
        .onChange(of: navigationManager.profileId) { _, newValue in
            if let profileId = newValue {
                toggleSessionFromDeeplink(profileId)
                navigationManager.clearProfileId()
            }
        }
        .onChange(of: requestAuthorizer.isAuthorized) { _, newValue in
            if newValue {
                showIntroScreen = false
            } else {
                showIntroScreen = true
            }
        }
        .onChange(of: profiles) { oldValue, newValue in
            if !newValue.isEmpty {
                loadApp()
            }
        }
        .onReceive(strategyManager.$errorMessage) { errorMessage in
            if let message = errorMessage {
                showErrorAlert(message: message)
            }
        }
        .onAppear {
            loadApp()
        }
        .onDisappear {
            unloadApp()
        }.sheet(isPresented: $showIntroScreen) {
            IntroView {
                requestAuthorizer.requestAuthorization()
            }.interactiveDismissDisabled()
        }.sheet(isPresented: $showActiveProfileView) {
            BlockedProfileView(profile: activeProfile)
        }.sheet(isPresented: $strategyManager.showCustomStrategyView) {
            BlockingStrategyActionView(
                customView: strategyManager.customStrategyView
            )
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { dismissAlert() }
        } message: {
            Text(alertMessage)
        }
    }

    private func toggleSessionFromDeeplink(_ profileId: String) {
        strategyManager.toggleSessionFromDeeplink(profileId, context: context)
    }

    private func incrementProfiles() {
        guard !profiles.isEmpty else { return }

        profileIndex = (profileIndex + 1) % profiles.count
    }

    private func decrementProfiles() {
        guard !profiles.isEmpty else { return }

        profileIndex = (profileIndex - 1 + profiles.count) % profiles.count
    }

    private func strategyButtonPress() {
        strategyManager
            .toggleBlocking(context: context, activeProfile: activeProfile)

        ratingManager.incrementLaunchCount()
    }

    private func loadApp() {
        strategyManager.loadActiveSession(context: context)

        if let sessionProfileId = activeSessionProfileId,
            let matchingProfile = profiles.first(where: {
                (profile: BlockedProfiles) in
                profile.id == sessionProfileId
            })
        {
            activeProfile = matchingProfile
        } else {
            activeProfile = profiles[safe: profileIndex]
        }
    }

    private func unloadApp() {
        strategyManager.stopTimer()
    }

    private func showErrorAlert(message: String) {
        alertTitle = "Whoops"
        alertMessage = message
        showingAlert = true
    }

    private func dismissAlert() {
        showingAlert = false
    }
}

#Preview {
    HomeView()
        .environmentObject(RequestAuthorizer())
        .environmentObject(TipManager())
        .environmentObject(NavigationManager())
        .environmentObject(StrategyManager())
        .defaultAppStorage(UserDefaults(suiteName: "preview")!)
        .onAppear {
            UserDefaults(suiteName: "preview")!.set(
                false,
                forKey: "showIntroScreen"
            )
        }
}
