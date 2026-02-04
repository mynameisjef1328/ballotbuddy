import SwiftUI

struct RemindersView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @ObservedObject var preferences: UserPreferences

    @State private var showAddReminder = false
    @State private var electionName = ""
    @State private var electionDate = Date()
    @State private var selectedReminderTypes: Set<ReminderType> = Set(ReminderType.allCases)
    @State private var addToCalendar = true
    @State private var showToast = false
    @State private var toastMessage = ""

    var savedReminders: [ReminderPreference] {
        notificationManager.getReminderPreferences()
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        electionCountdownSection
                        addReminderSection
                        savedRemindersSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }

                // Toast overlay
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(AppTheme.successGreen))
                            .padding(.bottom, 30)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(), value: showToast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Reminders")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Election Countdown

    private var electionCountdownSection: some View {
        Group {
            if let election = ElectionData.nextElection {
                VStack(spacing: 8) {
                    Text("Next Election")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)

                    Text(election.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("\(election.daysUntil) days away")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.accentBlue)

                    Text(election.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .cardStyle()
            }
        }
    }

    // MARK: - Add Reminder

    private var addReminderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "bell.badge", title: "Set Election Reminder")

            TextField("Election name", text: $electionName)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textPrimary)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.cardBackground))
                .placeholder(when: electionName.isEmpty) {
                    Text("e.g., 2026 Midterm Elections")
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.leading, 12)
                }

            DatePicker("Election Date", selection: $electionDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundColor(AppTheme.textPrimary)
                .tint(AppTheme.accentBlue)

            VStack(alignment: .leading, spacing: 8) {
                Text("Remind me:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)

                ForEach(ReminderType.allCases, id: \.self) { type in
                    ReminderTypeToggle(
                        type: type,
                        isSelected: selectedReminderTypes.contains(type)
                    ) {
                        HapticManager.shared.selection()
                        if selectedReminderTypes.contains(type) {
                            selectedReminderTypes.remove(type)
                        } else {
                            selectedReminderTypes.insert(type)
                        }
                    }
                }
            }

            Toggle(isOn: $addToCalendar) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(AppTheme.accentBlue)
                    Text("Also add to Calendar")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .tint(AppTheme.accentBlue)

            Button {
                scheduleReminders()
            } label: {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("Set Reminders")
                }
            }
            .buttonStyle(ActionButtonStyle(color: AppTheme.accentBlue))
            .disabled(electionName.isEmpty || selectedReminderTypes.isEmpty)
            .opacity(electionName.isEmpty || selectedReminderTypes.isEmpty ? 0.5 : 1.0)
        }
        .cardStyle()
    }

    // MARK: - Saved Reminders

    private var savedRemindersSection: some View {
        Group {
            if !savedReminders.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionHeader(icon: "bell.circle", title: "Scheduled Reminders")
                        Spacer()
                        Button {
                            HapticManager.shared.importantAction()
                            notificationManager.cancelAllReminders()
                            showToastMessage("All reminders cleared")
                        } label: {
                            Text("Clear All")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.accentRed)
                        }
                    }

                    // Group by election name
                    let grouped = Dictionary(grouping: savedReminders) { $0.electionName }
                    ForEach(Array(grouped.keys.sorted()), id: \.self) { name in
                        if let reminders = grouped[name] {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)

                                ForEach(reminders, id: \.reminderType) { reminder in
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.accentBlue)
                                        Text(reminderTypeLabel(reminder.reminderType))
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.textSecondary)
                                        Spacer()
                                        Text(reminder.electionDate, style: .date)
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.cardBackground))
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Actions

    private func scheduleReminders() {
        HapticManager.shared.importantAction()

        notificationManager.requestAuthorization { granted, _ in
            guard granted else {
                showToastMessage("Please enable notifications in Settings")
                return
            }

            let group = DispatchGroup()

            for type in selectedReminderTypes {
                group.enter()
                notificationManager.scheduleElectionReminder(
                    electionName: electionName,
                    electionDate: electionDate,
                    reminderType: type
                ) { _, _ in
                    group.leave()
                }
            }

            if addToCalendar {
                group.enter()
                calendarManager.requestAccess { granted, _ in
                    if granted {
                        calendarManager.addElectionToCalendar(
                            electionName: electionName,
                            electionDate: electionDate
                        ) { _, _, _ in
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                HapticManager.shared.reminderScheduled()
                showToastMessage("Reminders set for \(electionName)!")
                electionName = ""
            }
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }

    private func reminderTypeLabel(_ type: ReminderType) -> String {
        switch type {
        case .oneWeekBefore: return "1 week before"
        case .oneDayBefore: return "1 day before"
        case .morningOf: return "Morning of (8 AM)"
        }
    }
}

// MARK: - Reminder Type Toggle

struct ReminderTypeToggle: View {
    let type: ReminderType
    let isSelected: Bool
    let onToggle: () -> Void

    var label: String {
        switch type {
        case .oneWeekBefore: return "1 week before"
        case .oneDayBefore: return "1 day before"
        case .morningOf: return "Morning of election"
        }
    }

    var icon: String {
        switch type {
        case .oneWeekBefore: return "calendar"
        case .oneDayBefore: return "sun.max"
        case .morningOf: return "alarm"
        }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AppTheme.accentBlue : AppTheme.textMuted)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - ReminderType Conformance

extension ReminderType: CaseIterable {
    static var allCases: [ReminderType] = [.oneWeekBefore, .oneDayBefore, .morningOf]
}

// MARK: - Placeholder Modifier

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
