import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private override init() {
        super.init()
        checkAuthorizationStatus()
    }

    // Check current notification authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // Request notification permissions with a clear value proposition
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted, error)
            }
        }
    }

    // Schedule election reminder notification
    func scheduleElectionReminder(
        electionName: String,
        electionDate: Date,
        reminderType: ReminderType,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // Calculate trigger date based on reminder type
        let triggerDate: Date
        let calendar = Calendar.current

        switch reminderType {
        case .oneWeekBefore:
            triggerDate = calendar.date(byAdding: .day, value: -7, to: electionDate) ?? electionDate
        case .oneDayBefore:
            triggerDate = calendar.date(byAdding: .day, value: -1, to: electionDate) ?? electionDate
        case .morningOf:
            var components = calendar.dateComponents([.year, .month, .day], from: electionDate)
            components.hour = 8 // 8 AM
            components.minute = 0
            triggerDate = calendar.date(from: components) ?? electionDate
        }

        // Don't schedule if the trigger date is in the past
        guard triggerDate > Date() else {
            completion(false, NSError(domain: "NotificationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Reminder date is in the past"]))
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Election Reminder"
        content.body = reminderType.notificationBody(electionName: electionName)
        content.sound = .default
        content.badge = 1

        // Create trigger
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        // Create unique identifier
        let identifier = "election-\(electionName)-\(reminderType.rawValue)-\(electionDate.timeIntervalSince1970)"

        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error)
                } else {
                    // Save reminder preference
                    self.saveReminderPreference(
                        electionName: electionName,
                        electionDate: electionDate,
                        reminderType: reminderType
                    )
                    completion(true, nil)
                }
            }
        }
    }

    // Cancel all election reminders
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UserDefaults.standard.removeObject(forKey: "electionReminders")
    }

    // Cancel specific election reminder
    func cancelReminder(electionName: String, electionDate: Date, reminderType: ReminderType) {
        let identifier = "election-\(electionName)-\(reminderType.rawValue)-\(electionDate.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        // Remove from UserDefaults
        var reminders = getReminderPreferences()
        reminders.removeAll { reminder in
            reminder.electionName == electionName &&
            reminder.electionDate == electionDate &&
            reminder.reminderType == reminderType
        }
        saveReminders(reminders)
    }

    // Save reminder preference to UserDefaults
    private func saveReminderPreference(electionName: String, electionDate: Date, reminderType: ReminderType) {
        var reminders = getReminderPreferences()
        let newReminder = ReminderPreference(
            electionName: electionName,
            electionDate: electionDate,
            reminderType: reminderType
        )
        reminders.append(newReminder)
        saveReminders(reminders)
    }

    private func saveReminders(_ reminders: [ReminderPreference]) {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: "electionReminders")
        }
    }

    // Get saved reminder preferences
    func getReminderPreferences() -> [ReminderPreference] {
        guard let data = UserDefaults.standard.data(forKey: "electionReminders"),
              let reminders = try? JSONDecoder().decode([ReminderPreference].self, from: data) else {
            return []
        }
        return reminders
    }

    // Get pending notifications
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}

// MARK: - Supporting Types

enum ReminderType: String, Codable {
    case oneWeekBefore = "one_week"
    case oneDayBefore = "one_day"
    case morningOf = "morning_of"

    func notificationBody(electionName: String) -> String {
        switch self {
        case .oneWeekBefore:
            return "\(electionName) is coming up in one week. Make sure you're registered and know your polling location!"
        case .oneDayBefore:
            return "\(electionName) is tomorrow! Have you checked your polling location and what's on the ballot?"
        case .morningOf:
            return "Today is \(electionName)! Don't forget to vote. Polls are open now."
        }
    }
}

struct ReminderPreference: Codable {
    let electionName: String
    let electionDate: Date
    let reminderType: ReminderType
}
