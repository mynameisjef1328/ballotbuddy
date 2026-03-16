import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: UserPreferences
    @Environment(\.dismiss) var dismiss
    @State private var showStateSelector = false

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        stateSection
                        shareSection
                        aboutSection
                        linksSection
                        versionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentBlue)
                }
            }
            .sheet(isPresented: $showStateSelector) {
                StateSelectorSheet(preferences: preferences)
            }
        }
    }

    // MARK: - State Section

    private var stateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "mappin.circle", title: "Your State")

            Button {
                HapticManager.shared.buttonTap()
                showStateSelector = true
            } label: {
                HStack {
                    if let state = preferences.selectedState {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Tap to change")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    } else {
                        Text("Select a state")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
            }
        }
        .cardStyle()
    }

    // MARK: - Share

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "square.and.arrow.up", title: "Share Ballot Buddy")

            ShareLink(
                item: URL(string: "https://apps.apple.com/app/ballot-buddy/id6746427498")!,
                subject: Text("Ballot Buddy"),
                message: Text("Check out Ballot Buddy — it helps you get ready to vote with personalized state info, checklists, and reminders.")
            ) {
                HStack {
                    Text("Share with friends")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
            }

            Text("Help others get ready to vote!")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)
        }
        .cardStyle()
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "info.circle", title: "About")

            VStack(alignment: .leading, spacing: 8) {
                Text("Ballot Buddy is your personal voting companion. We help you stay informed and prepared for every election.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                Text("We don't collect personal data, require login, or track your activity. Your voting information stays on your device.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12))
                    Text("Privacy-first design")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppTheme.successGreen)
                .padding(.top, 4)
            }
        }
        .cardStyle()
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsLink(icon: "hand.raised.fill", title: "Privacy Policy") {
                openURL("https://mynameisjef1328.github.io/ballotbuddy-support/privacy.html")
            }

            SettingsLink(icon: "questionmark.circle", title: "Support") {
                openURL("https://mynameisjef1328.github.io/ballotbuddy-support/")
            }

            SettingsLink(icon: "globe", title: "Vote.org") {
                openURL("https://www.vote.org")
            }
        }
        .cardStyle()
    }

    // MARK: - Version

    private var versionSection: some View {
        VStack(spacing: 4) {
            Text("Ballot Buddy")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Link Row

struct SettingsLink: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.accentBlue)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
        }
    }
}

// MARK: - State Selector Sheet

struct StateSelectorSheet: View {
    @ObservedObject var preferences: UserPreferences
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var filteredStates: [StateVotingInfo] {
        if searchText.isEmpty { return VotingDataStore.states }
        return VotingDataStore.states.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textMuted)
                        TextField("Search states...", text: $searchText)
                            .foregroundColor(AppTheme.textPrimary)
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(filteredStates) { state in
                                Button {
                                    HapticManager.shared.stateSelected()
                                    preferences.changeState(stateId: state.id)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(state.id)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(AppTheme.accentBlue)
                                            .frame(width: 36)
                                        Text(state.name)
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        if preferences.selectedStateId == state.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppTheme.accentBlue)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(preferences.selectedStateId == state.id ? AppTheme.accentBlue.opacity(0.15) : Color.clear)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.accentBlue)
                }
            }
        }
    }
}
