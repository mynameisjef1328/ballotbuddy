import SwiftUI

struct StateInfoView: View {
    let state: StateVotingInfo

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    registrationSection
                    votingMethodsSection
                    voterIDSection
                    pollingSection
                    keyInfoSection
                    officialWebsiteSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(state.name)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Registration

    private var registrationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "pencil.and.list.clipboard", title: "Registration")

            InfoRow(
                icon: "calendar",
                label: "Registration Deadline",
                value: state.registrationDeadlineDescription
            )

            InfoRow(
                icon: "globe",
                label: "Online Registration",
                value: state.onlineRegistration ? "Available" : "Not available",
                valueColor: state.onlineRegistration ? AppTheme.successGreen : AppTheme.accentRed
            )

            InfoRow(
                icon: "person.badge.plus",
                label: "Same-Day Registration",
                value: state.sameDayRegistration ? "Available" : "Not available",
                valueColor: state.sameDayRegistration ? AppTheme.successGreen : AppTheme.accentRed
            )

            Button {
                HapticManager.shared.buttonTap()
                openURL("https://www.vote.org/am-i-registered-to-vote/")
            } label: {
                Text("Check Your Registration Status")
            }
            .buttonStyle(ActionButtonStyle(color: AppTheme.successGreen))
        }
        .cardStyle()
    }

    // MARK: - Voting Methods

    private var votingMethodsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "ballot", title: "Voting Methods")

            InfoRow(
                icon: "clock.arrow.circlepath",
                label: "Early Voting",
                value: state.earlyVoting ?
                    "Available — starts \(state.earlyVotingDays ?? 0) days before election" :
                    "Not available",
                valueColor: state.earlyVoting ? AppTheme.successGreen : AppTheme.accentRed
            )

            InfoRow(
                icon: "envelope.fill",
                label: "Absentee / Mail-In Voting",
                value: state.noExcuseAbsentee ?
                    "No excuse needed — any voter can request" :
                    "Excuse required to vote absentee",
                valueColor: state.noExcuseAbsentee ? AppTheme.successGreen : AppTheme.warningOrange
            )

            Button {
                HapticManager.shared.buttonTap()
                let slug = state.name.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: ".", with: "")
                openURL("https://www.vote.org/absentee-ballot/\(slug)/")
            } label: {
                Text("Request Absentee Ballot")
            }
            .buttonStyle(ActionButtonStyle(color: AppTheme.accentBlue))
        }
        .cardStyle()
    }

    // MARK: - Voter ID

    private var voterIDSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "person.text.rectangle", title: "Voter ID Requirements")

            if state.voterIDRequired {
                HStack {
                    BadgeView(
                        text: state.voterIDType + " ID Required",
                        color: state.voterIDType.contains("Strict") ? AppTheme.accentRed : AppTheme.warningOrange
                    )
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Accepted Forms of ID:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)

                    ForEach(state.acceptedIDs, id: \.self) { idType in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.successGreen)
                                .padding(.top, 2)
                            Text(idType)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            } else {
                HStack {
                    BadgeView(text: "No ID Required", color: AppTheme.successGreen)
                    Spacer()
                }
                ForEach(state.acceptedIDs, id: \.self) { note in
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Polling

    private var pollingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "clock.fill", title: "Polling Information")

            InfoRow(
                icon: "clock",
                label: "Polling Hours",
                value: state.pollingHours
            )

            Button {
                HapticManager.shared.buttonTap()
                openURL("https://www.vote.org/polling-place-locator/")
            } label: {
                Text("Find Your Polling Place")
            }
            .buttonStyle(ActionButtonStyle(color: AppTheme.accentRed))
        }
        .cardStyle()
    }

    // MARK: - Key Info

    private var keyInfoSection: some View {
        Group {
            if !state.keyInfo.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(icon: "lightbulb.fill", title: "Key Information")

                    ForEach(state.keyInfo, id: \.self) { info in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.warningOrange)
                                .padding(.top, 2)
                            Text(info)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Official Website

    private var officialWebsiteSection: some View {
        Button {
            HapticManager.shared.buttonTap()
            openURL(state.stateWebsite)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accentBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Official \(state.name) Elections")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Visit your state's official election website")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .cardStyle()
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accentBlue)
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}
