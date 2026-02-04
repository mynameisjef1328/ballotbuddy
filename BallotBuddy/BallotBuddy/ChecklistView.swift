import SwiftUI

struct ChecklistView: View {
    @ObservedObject var preferences: UserPreferences
    @State private var showResetAlert = false

    var categories: [String] {
        // Preserve order
        var seen = Set<String>()
        return preferences.checklistItems.compactMap { item in
            if seen.contains(item.category) { return nil }
            seen.insert(item.category)
            return item.category
        }
    }

    var completedCount: Int {
        preferences.checklistItems.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        preferences.checklistItems.count
    }

    var progress: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        progressSection
                        checklistSections
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Voting Checklist")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.buttonTap()
                        showResetAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .alert("Reset Checklist?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    HapticManager.shared.importantAction()
                    preferences.resetChecklist()
                }
            } message: {
                Text("This will uncheck all items. You can re-check them as you complete each step.")
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("\(completedCount) of \(totalCount) completed")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()

                ZStack {
                    Circle()
                        .stroke(AppTheme.cardBackground, lineWidth: 6)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AppTheme.successGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }

            if completedCount == totalCount && totalCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "party.popper.fill")
                    Text("You're all set for Election Day!")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.successGreen)
                .padding(.top, 4)
            }
        }
        .cardStyle()
    }

    // MARK: - Checklist Sections

    private var checklistSections: some View {
        ForEach(categories, id: \.self) { category in
            VStack(alignment: .leading, spacing: 12) {
                Text(category)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                let items = preferences.checklistItems.filter { $0.category == category }
                ForEach(items) { item in
                    ChecklistItemRow(item: item) {
                        HapticManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            preferences.toggleChecklistItem(id: item.id)
                        }
                        if preferences.checklistItems.filter({ $0.isCompleted }).count == totalCount {
                            HapticManager.shared.success()
                        }
                    }
                }
            }
            .cardStyle()
        }
    }
}

// MARK: - Checklist Item Row

struct ChecklistItemRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(item.isCompleted ? AppTheme.successGreen : AppTheme.textMuted)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(item.isCompleted ? AppTheme.textMuted : AppTheme.textPrimary)
                        .strikethrough(item.isCompleted)

                    Text(item.detail)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}
