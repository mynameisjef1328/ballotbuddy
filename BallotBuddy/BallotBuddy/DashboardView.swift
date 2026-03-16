import SwiftUI

struct DashboardView: View {
    @ObservedObject var preferences: UserPreferences
    @State private var showingSettings = false
    @State private var showingStateInfo = false

    var state: StateVotingInfo? {
        preferences.selectedState
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Custom header
                    HStack {
                        Text("Ballot Buddy")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Button {
                            HapticManager.shared.buttonTap()
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    headerSection
                    countdownSection
                    quickInfoSection
                    actionsSection
                    resourcesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(preferences: preferences)
        }
        .sheet(isPresented: $showingStateInfo) {
            if let state = state {
                StateInfoSheet(state: state)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            if let state = state {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(AppTheme.accentBlue)
                    Text(state.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button("Change") {
                        HapticManager.shared.buttonTap()
                        showingSettings = true
                    }
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accentBlue)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Countdown

    private var countdownSection: some View {
        Group {
            if let election = ElectionData.nextElection {
                VStack(spacing: 12) {
                    Text(election.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("\(election.daysUntil)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.accentBlue)

                    Text("days until Election Day")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)

                    Text(election.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)

                    // Registration deadline warning
                    if let state = state, let deadlineDays = state.registrationDeadlineDays {
                        let daysUntilDeadline = election.daysUntil - (30 - deadlineDays) // approximate
                        if daysUntilDeadline > 0 && daysUntilDeadline <= 60 {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text("Registration deadline: \(state.registrationDeadlineDescription)")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(AppTheme.warningOrange)
                            .padding(.top, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .cardStyle()
            }
        }
    }

    // MARK: - Quick Info

    private var quickInfoSection: some View {
        Group {
            if let state = state {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Your State at a Glance")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    InfoRow(
                        icon: "calendar.badge.clock",
                        label: "Registration Deadline",
                        value: state.registrationDeadlineDescription
                    )

                    InfoRow(
                        icon: "envelope.fill",
                        label: "Mail-In / Absentee Voting",
                        value: state.noExcuseAbsentee ? "No excuse needed" : "Excuse required",
                        valueColor: state.noExcuseAbsentee ? AppTheme.successGreen : AppTheme.warningOrange
                    )

                    InfoRow(
                        icon: "clock.arrow.circlepath",
                        label: "Early Voting",
                        value: state.earlyVoting ? "Available (\(state.earlyVotingDays ?? 0) days before)" : "Not available",
                        valueColor: state.earlyVoting ? AppTheme.successGreen : AppTheme.accentRed
                    )

                    InfoRow(
                        icon: "person.text.rectangle",
                        label: "Voter ID",
                        value: state.voterIDRequired ? "\(state.voterIDType) ID required" : "No ID required",
                        valueColor: state.voterIDRequired ? AppTheme.warningOrange : AppTheme.successGreen
                    )

                    InfoRow(
                        icon: "clock.fill",
                        label: "Polling Hours",
                        value: state.pollingHours
                    )

                    Button {
                        HapticManager.shared.buttonTap()
                        showingStateInfo = true
                    } label: {
                        HStack {
                            Text("View Full Details")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(AppTheme.accentBlue)
                        .padding(.top, 4)
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Quick Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ActionCard(icon: "checkmark.circle", title: "Check\nRegistration", color: AppTheme.successGreen) {
                    HapticManager.shared.importantAction()
                    openURL("https://www.vote.org/am-i-registered-to-vote/")
                }

                ActionCard(icon: "calendar.badge.exclamationmark", title: "View\nDeadlines", color: AppTheme.warningOrange) {
                    HapticManager.shared.buttonTap()
                    openURL("https://www.vote.org/voter-registration-deadlines/")
                }

                ActionCard(icon: "envelope.open", title: "Absentee\nBallot", color: AppTheme.accentBlue) {
                    HapticManager.shared.buttonTap()
                    let baseURL = "https://www.vote.org/absentee-ballot/"
                    if let state = state {
                        let slug = state.name.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: ".", with: "")
                        openURL(baseURL + slug + "/")
                    } else {
                        openURL(baseURL)
                    }
                }

                ActionCard(icon: "mappin.and.ellipse", title: "Polling\nPlace", color: AppTheme.accentRed) {
                    HapticManager.shared.buttonTap()
                    openURL("https://www.vote.org/polling-place-locator/")
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Resources

    private var resourcesSection: some View {
        Group {
            if let state = state {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Resources")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Button {
                        HapticManager.shared.buttonTap()
                        openURL(state.stateWebsite)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundColor(AppTheme.accentBlue)
                            VStack(alignment: .leading) {
                                Text("\(state.name) Elections Website")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("Official state election information")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.cardBackground))
                    }

                    Button {
                        HapticManager.shared.buttonTap()
                        openURL("https://www.vote.org")
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppTheme.accentBlue)
                            VStack(alignment: .leading) {
                                Text("Vote.org")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("Voter registration and resources")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.cardBackground))
                    }
                }
                .cardStyle()
            }
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
            )
        }
    }
}

// MARK: - State Info Sheet

struct StateInfoSheet: View {
    let state: StateVotingInfo
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            StateInfoView(state: state)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(AppTheme.accentBlue)
                    }
                }
        }
    }
}
