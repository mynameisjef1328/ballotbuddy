import Foundation
import EventKit

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    private let eventStore = EKEventStore()
    @Published var isAuthorized = false

    private init() {
        checkAuthorizationStatus()
    }

    // Check current calendar authorization status
    func checkAuthorizationStatus() {
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        DispatchQueue.main.async {
            self.isAuthorized = status == .authorized || status == .fullAccess
        }
    }

    // Request calendar access with proper iOS version handling
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted, error)
                }
            }
        }
    }

    // Add election event to calendar
    func addElectionToCalendar(
        electionName: String,
        electionDate: Date,
        pollingLocation: String? = nil,
        notes: String? = nil,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        // Check authorization first
        guard isAuthorized else {
            requestAccess { granted, error in
                if granted {
                    self.performAddElectionToCalendar(
                        electionName: electionName,
                        electionDate: electionDate,
                        pollingLocation: pollingLocation,
                        notes: notes,
                        completion: completion
                    )
                } else {
                    completion(false, nil, error ?? NSError(domain: "CalendarManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access not granted"]))
                }
            }
            return
        }

        performAddElectionToCalendar(
            electionName: electionName,
            electionDate: electionDate,
            pollingLocation: pollingLocation,
            notes: notes,
            completion: completion
        )
    }

    private func performAddElectionToCalendar(
        electionName: String,
        electionDate: Date,
        pollingLocation: String?,
        notes: String?,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let event = EKEvent(eventStore: eventStore)
        event.title = electionName
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Set as all-day event
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: electionDate)
        event.startDate = startOfDay
        event.endDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)
        event.isAllDay = true

        // Add polling location if available
        if let location = pollingLocation, !location.isEmpty {
            event.location = location
            event.structuredLocation = EKStructuredLocation(title: location)
        }

        // Build comprehensive notes
        var eventNotes = "🗳️ Election Day - Make Your Voice Heard!\n\n"

        if let customNotes = notes, !customNotes.isEmpty {
            eventNotes += "\(customNotes)\n\n"
        }

        eventNotes += "Reminders:\n"
        eventNotes += "• Bring valid ID (check your state's requirements)\n"
        eventNotes += "• Check polling hours before you go\n"
        eventNotes += "• Review your sample ballot\n"
        eventNotes += "• Share this important date with friends and family\n\n"
        eventNotes += "Created by Ballot Buddy - Your Election Companion"

        event.notes = eventNotes

        // Add alarms
        // 1 week before at 9 AM
        if let oneWeekBefore = calendar.date(byAdding: .day, value: -7, to: startOfDay) {
            var components = calendar.dateComponents([.year, .month, .day], from: oneWeekBefore)
            components.hour = 9
            components.minute = 0
            if let alarmDate = calendar.date(from: components) {
                event.addAlarm(EKAlarm(absoluteDate: alarmDate))
            }
        }

        // Morning of election at 8 AM
        var morningComponents = calendar.dateComponents([.year, .month, .day], from: startOfDay)
        morningComponents.hour = 8
        morningComponents.minute = 0
        if let morningDate = calendar.date(from: morningComponents) {
            event.addAlarm(EKAlarm(absoluteDate: morningDate))
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            DispatchQueue.main.async {
                completion(true, event.eventIdentifier, nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion(false, nil, error)
            }
        }
    }

    // Remove election event from calendar
    func removeElectionFromCalendar(eventIdentifier: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isAuthorized else {
            completion(false, NSError(domain: "CalendarManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Calendar access not granted"]))
            return
        }

        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            completion(false, NSError(domain: "CalendarManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Event not found"]))
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
            DispatchQueue.main.async {
                completion(true, nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }

    // Check if event exists in calendar
    func eventExists(eventIdentifier: String) -> Bool {
        guard isAuthorized else { return false }
        return eventStore.event(withIdentifier: eventIdentifier) != nil
    }

    // Get user-friendly authorization status message
    func getAuthorizationMessage() -> String {
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }

        switch status {
        case .notDetermined:
            return "Calendar access not yet requested. Tap 'Add to Calendar' to enable this feature."
        case .restricted:
            return "Calendar access is restricted on this device."
        case .denied:
            return "Calendar access was denied. Please enable it in Settings > Ballot Buddy > Calendars to add election dates."
        case .authorized, .fullAccess:
            return "Calendar access granted"
        case .writeOnly:
            return "Calendar write access granted"
        @unknown default:
            return "Unknown calendar authorization status"
        }
    }
}
