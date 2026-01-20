import Foundation
import UIKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // Light impact - for subtle interactions like button taps
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    // Medium impact - for standard button presses
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    // Heavy impact - for important actions
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // Soft impact - for gentle interactions (iOS 13+)
    func soft() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred()
        } else {
            light()
        }
    }

    // Rigid impact - for precise interactions (iOS 13+)
    func rigid() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred()
        } else {
            medium()
        }
    }

    // Success notification - for successful actions
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    // Warning notification - for warning states
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    // Error notification - for error states
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    // Selection changed - for picker/segment control changes
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // Custom intensity impact (iOS 13+)
    func customImpact(intensity: CGFloat) {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred(intensity: max(0.0, min(1.0, intensity)))
        } else {
            medium()
        }
    }

    // Haptic for button tap - convenience method
    func buttonTap() {
        soft()
    }

    // Haptic for important button - convenience method
    func importantAction() {
        medium()
    }

    // Haptic for navigation - convenience method
    func navigate() {
        light()
    }

    // Haptic for state selection - convenience method
    func stateSelected() {
        selection()
    }

    // Haptic for reminder scheduled - convenience method
    func reminderScheduled() {
        success()
    }

    // Haptic for calendar event added - convenience method
    func calendarEventAdded() {
        success()
    }

    // Haptic for share action - convenience method
    func share() {
        light()
    }
}
