import Foundation

// MARK: - State Voting Data Model

struct StateVotingInfo: Identifiable {
    let id: String // State abbreviation
    let name: String
    let registrationDeadlineDays: Int? // Days before election, nil = no registration required
    let onlineRegistration: Bool
    let sameDayRegistration: Bool
    let earlyVoting: Bool
    let earlyVotingDays: Int? // Days before election early voting starts
    let noExcuseAbsentee: Bool
    let voterIDRequired: Bool
    let voterIDType: String // "Strict Photo", "Photo", "Non-Photo", "None"
    let acceptedIDs: [String]
    let pollingHours: String
    let stateWebsite: String
    let keyInfo: [String] // Additional notable facts

    var registrationDeadlineDescription: String {
        guard let days = registrationDeadlineDays else {
            return "No registration required"
        }
        if days == 0 { return "Same-day registration available" }
        return "\(days) days before election"
    }
}

// MARK: - Election Info

struct ElectionInfo: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let type: ElectionType

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
    }

    var isPast: Bool { date < Date() }
}

enum ElectionType: String, CaseIterable {
    case general = "General Election"
    case primary = "Primary Election"
    case local = "Local Election"
    case special = "Special Election"
    case runoff = "Runoff Election"
}

// MARK: - Checklist

struct ChecklistItem: Identifiable, Codable {
    let id: String
    let title: String
    let detail: String
    let category: String
    var isCompleted: Bool
}

// MARK: - Upcoming Elections

struct ElectionData {
    static let upcoming: [ElectionInfo] = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return [
            ElectionInfo(name: "2026 Primary Elections", date: df.date(from: "2026-06-09") ?? Date(), type: .primary),
            ElectionInfo(name: "2026 Midterm Elections", date: df.date(from: "2026-11-03") ?? Date(), type: .general),
        ]
    }()

    static var nextElection: ElectionInfo? {
        upcoming.filter { !$0.isPast }.sorted { $0.date < $1.date }.first
    }
}

// MARK: - Default Checklist Items

extension ChecklistItem {
    static let defaultItems: [ChecklistItem] = [
        // Before Election Day
        ChecklistItem(id: "reg_check", title: "Verify voter registration", detail: "Confirm your registration is active and your information is up to date.", category: "Before Election Day", isCompleted: false),
        ChecklistItem(id: "polling_place", title: "Find your polling place", detail: "Look up your assigned polling location so you know where to go.", category: "Before Election Day", isCompleted: false),
        ChecklistItem(id: "research", title: "Research candidates and measures", detail: "Review who and what will be on your ballot before you vote.", category: "Before Election Day", isCompleted: false),
        ChecklistItem(id: "id_ready", title: "Prepare your ID", detail: "Check your state's voter ID requirements and have the right documents ready.", category: "Before Election Day", isCompleted: false),
        ChecklistItem(id: "plan_time", title: "Plan your voting time", detail: "Check polling hours and decide when you'll go to avoid long waits.", category: "Before Election Day", isCompleted: false),
        ChecklistItem(id: "absentee_check", title: "Request absentee ballot (if needed)", detail: "If you can't vote in person, request a mail-in or absentee ballot before the deadline.", category: "Before Election Day", isCompleted: false),

        // Election Day
        ChecklistItem(id: "bring_id", title: "Bring your ID to the polls", detail: "Have your photo ID, voter registration card, or required documentation.", category: "Election Day", isCompleted: false),
        ChecklistItem(id: "go_vote", title: "Go vote!", detail: "Head to your polling place and cast your ballot.", category: "Election Day", isCompleted: false),
        ChecklistItem(id: "check_ballot", title: "Review your ballot before submitting", detail: "Double-check all your selections before you finalize your vote.", category: "Election Day", isCompleted: false),
        ChecklistItem(id: "sticker", title: "Get your \"I Voted\" sticker", detail: "Wear it proudly and encourage others to vote too!", category: "Election Day", isCompleted: false),

        // After Voting
        ChecklistItem(id: "share_vote", title: "Encourage others to vote", detail: "Share that you voted and remind friends and family.", category: "After Voting", isCompleted: false),
        ChecklistItem(id: "track_absentee", title: "Track your absentee ballot (if applicable)", detail: "If you voted by mail, check that your ballot was received and counted.", category: "After Voting", isCompleted: false),
    ]
}
