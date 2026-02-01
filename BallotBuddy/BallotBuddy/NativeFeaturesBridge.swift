import Foundation
import WebKit

class NativeFeaturesBridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?

    private let notificationManager = NotificationManager.shared
    private let calendarManager = CalendarManager.shared
    private let hapticManager = HapticManager.shared

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }

        switch action {
        // MARK: - Haptic Feedback Actions
        case "haptic":
            handleHaptic(body: body)

        // MARK: - Notification Actions
        case "requestNotificationPermission":
            handleRequestNotificationPermission(body: body)

        case "scheduleElectionReminder":
            handleScheduleElectionReminder(body: body)

        case "cancelReminder":
            handleCancelReminder(body: body)

        case "cancelAllReminders":
            handleCancelAllReminders(body: body)

        case "getNotificationStatus":
            handleGetNotificationStatus(body: body)

        case "getReminderPreferences":
            handleGetReminderPreferences(body: body)

        // MARK: - Calendar Actions
        case "requestCalendarPermission":
            handleRequestCalendarPermission(body: body)

        case "addToCalendar":
            handleAddToCalendar(body: body)

        case "removeFromCalendar":
            handleRemoveFromCalendar(body: body)

        case "getCalendarStatus":
            handleGetCalendarStatus(body: body)

        // MARK: - Share Action
        case "share":
            handleShare(body: body)

        default:
            print("Unknown action: \(action)")
        }
    }

    // MARK: - Haptic Handlers

    private func handleHaptic(body: [String: Any]) {
        guard let type = body["type"] as? String else { return }

        DispatchQueue.main.async {
            switch type {
            case "light":
                self.hapticManager.light()
            case "medium":
                self.hapticManager.medium()
            case "heavy":
                self.hapticManager.heavy()
            case "soft":
                self.hapticManager.soft()
            case "rigid":
                self.hapticManager.rigid()
            case "success":
                self.hapticManager.success()
            case "warning":
                self.hapticManager.warning()
            case "error":
                self.hapticManager.error()
            case "selection":
                self.hapticManager.selection()
            case "buttonTap":
                self.hapticManager.buttonTap()
            case "importantAction":
                self.hapticManager.importantAction()
            case "navigate":
                self.hapticManager.navigate()
            case "stateSelected":
                self.hapticManager.stateSelected()
            case "reminderScheduled":
                self.hapticManager.reminderScheduled()
            case "calendarEventAdded":
                self.hapticManager.calendarEventAdded()
            case "share":
                self.hapticManager.share()
            default:
                self.hapticManager.buttonTap()
            }
        }
    }

    // MARK: - Notification Handlers

    private func handleRequestNotificationPermission(body: [String: Any]) {
        let callbackId = body["callbackId"] as? String

        notificationManager.requestAuthorization { granted, error in
            let response: [String: Any] = [
                "success": granted,
                "authorized": granted,
                "error": error?.localizedDescription ?? ""
            ]
            self.sendCallback(callbackId: callbackId, response: response)
        }
    }

    private func handleScheduleElectionReminder(body: [String: Any]) {
        guard let electionName = body["electionName"] as? String,
              let dateString = body["electionDate"] as? String,
              let reminderTypeString = body["reminderType"] as? String,
              let electionDate = ISO8601DateFormatter().date(from: dateString),
              let reminderType = ReminderType(rawValue: reminderTypeString) else {
            let callbackId = body["callbackId"] as? String
            sendCallback(callbackId: callbackId, response: ["success": false, "error": "Invalid parameters"])
            return
        }

        let callbackId = body["callbackId"] as? String

        notificationManager.scheduleElectionReminder(
            electionName: electionName,
            electionDate: electionDate,
            reminderType: reminderType
        ) { success, error in
            let response: [String: Any] = [
                "success": success,
                "error": error?.localizedDescription ?? ""
            ]
            self.sendCallback(callbackId: callbackId, response: response)
        }
    }

    private func handleCancelReminder(body: [String: Any]) {
        guard let electionName = body["electionName"] as? String,
              let dateString = body["electionDate"] as? String,
              let reminderTypeString = body["reminderType"] as? String,
              let electionDate = ISO8601DateFormatter().date(from: dateString),
              let reminderType = ReminderType(rawValue: reminderTypeString) else {
            return
        }

        notificationManager.cancelReminder(
            electionName: electionName,
            electionDate: electionDate,
            reminderType: reminderType
        )
    }

    private func handleCancelAllReminders(body: [String: Any]) {
        notificationManager.cancelAllReminders()
    }

    private func handleGetNotificationStatus(body: [String: Any]) {
        let callbackId = body["callbackId"] as? String

        notificationManager.checkAuthorizationStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let response: [String: Any] = [
                "authorized": self.notificationManager.isAuthorized
            ]
            self.sendCallback(callbackId: callbackId, response: response)
        }
    }

    private func handleGetReminderPreferences(body: [String: Any]) {
        let callbackId = body["callbackId"] as? String
        let preferences = notificationManager.getReminderPreferences()

        let preferencesData = preferences.map { pref -> [String: Any] in
            return [
                "electionName": pref.electionName,
                "electionDate": ISO8601DateFormatter().string(from: pref.electionDate),
                "reminderType": pref.reminderType.rawValue
            ]
        }

        let response: [String: Any] = [
            "preferences": preferencesData
        ]
        sendCallback(callbackId: callbackId, response: response)
    }

    // MARK: - Calendar Handlers

    private func handleRequestCalendarPermission(body: [String: Any]) {
        let callbackId = body["callbackId"] as? String

        calendarManager.requestAccess { granted, error in
            let response: [String: Any] = [
                "success": granted,
                "authorized": granted,
                "error": error?.localizedDescription ?? "",
                "message": self.calendarManager.getAuthorizationMessage()
            ]
            self.sendCallback(callbackId: callbackId, response: response)
        }
    }

    private func handleAddToCalendar(body: [String: Any]) {
        guard let electionName = body["electionName"] as? String,
              let dateString = body["electionDate"] as? String,
              let electionDate = ISO8601DateFormatter().date(from: dateString) else {
            let callbackId = body["callbackId"] as? String
            sendCallback(callbackId: callbackId, response: ["success": false, "error": "Invalid parameters"])
            return
        }

        let callbackId = body["callbackId"] as? String
        let pollingLocation = body["pollingLocation"] as? String
        let notes = body["notes"] as? String

        calendarManager.addElectionToCalendar(
            electionName: electionName,
            electionDate: electionDate,
            pollingLocation: pollingLocation,
            notes: notes
        ) { success, eventIdentifier, error in
            var response: [String: Any] = [
                "success": success,
                "error": error?.localizedDescription ?? ""
            ]
            if let eventId = eventIdentifier {
                response["eventIdentifier"] = eventId
            }
            self.sendCallback(callbackId: callbackId, response: response)
        }
    }

    private func handleRemoveFromCalendar(body: [String: Any]) {
        guard let eventIdentifier = body["eventIdentifier"] as? String else {
            let callbackId = body["callbackId"] as? String
            sendCallback(callbackId: callbackId, response: ["success": false, "error": "Invalid event identifier"])
            return
        }

        let callbackId = body["callbackId"] as? String

        calendarManager.removeElectionFromCalendar(eventIdentifier: eventIdentifier) { success, error in
            let response: [String: Any] = [
                "success": success,
                "error": error?.localizedDescription ?? ""
            ]
            self.sendCallback(callbackId: callbackId, response: response)
        }
    }

    private func handleGetCalendarStatus(body: [String: Any]) {
        let callbackId = body["callbackId"] as? String

        calendarManager.checkAuthorizationStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let response: [String: Any] = [
                "authorized": self.calendarManager.isAuthorized,
                "message": self.calendarManager.getAuthorizationMessage()
            ]
            self.sendCallback(callbackId: callbackId, response: response)
        }
    }

    // MARK: - Share Handler

    private func handleShare(body: [String: Any]) {
        guard let text = body["text"] as? String else { return }
        let callbackId = body["callbackId"] as? String

        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController else {
                self.sendCallback(callbackId: callbackId, response: ["success": false, "error": "No root view controller"])
                return
            }

            // Required for iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            activityVC.completionWithItemsHandler = { _, completed, _, error in
                self.sendCallback(callbackId: callbackId, response: [
                    "success": completed,
                    "error": error?.localizedDescription ?? ""
                ])
            }

            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Helper Methods

    private func sendCallback(callbackId: String?, response: [String: Any]) {
        guard let callbackId = callbackId else { return }

        if let jsonData = try? JSONSerialization.data(withJSONObject: response, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let script = "window.NativeBridge.handleCallback('\(callbackId)', \(jsonString));"
            DispatchQueue.main.async {
                self.webView?.evaluateJavaScript(script, completionHandler: nil)
            }
        }
    }
}
