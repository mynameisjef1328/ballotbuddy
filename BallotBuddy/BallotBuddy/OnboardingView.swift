import SwiftUI

struct OnboardingView: View {
    @ObservedObject var preferences: UserPreferences
    @State private var selectedStateId: String? = nil
    @State private var searchText = ""

    var filteredStates: [StateVotingInfo] {
        if searchText.isEmpty {
            return VotingDataStore.states
        }
        return VotingDataStore.states.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundColor(AppTheme.accentBlue)
                        .padding(.top, 40)

                    Text("Ballot Buddy")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Your personal voting companion.\nSelect your state to get started.")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textMuted)
                    TextField("Search states...", text: $searchText)
                        .foregroundColor(AppTheme.textPrimary)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.cardBackground)
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // State list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredStates) { state in
                            StateSelectionRow(
                                state: state,
                                isSelected: selectedStateId == state.id
                            ) {
                                HapticManager.shared.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedStateId = state.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }

                Spacer()
            }

            // Continue button
            VStack {
                Spacer()

                if let stateId = selectedStateId {
                    Button {
                        HapticManager.shared.importantAction()
                        preferences.completeOnboarding(stateId: stateId)
                    } label: {
                        HStack {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(ActionButtonStyle(color: AppTheme.accentBlue))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: selectedStateId)
        }
    }
}

// MARK: - State Selection Row

struct StateSelectionRow: View {
    let state: StateVotingInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(state.id)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : AppTheme.accentBlue)
                    .frame(width: 36)

                Text(state.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.accentBlue)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.accentBlue.opacity(0.2) : AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentBlue : Color.clear, lineWidth: 1.5)
            )
        }
    }
}
