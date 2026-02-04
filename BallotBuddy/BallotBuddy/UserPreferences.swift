import Foundation
import Combine

// MARK: - User Preferences Manager

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private let stateKey = "bb_selected_state"
    private let onboardedKey = "bb_has_onboarded"
    private let checklistKey = "bb_checklist_items"

    @Published var selectedStateId: String? {
        didSet {
            UserDefaults.standard.set(selectedStateId, forKey: stateKey)
        }
    }

    @Published var hasOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(hasOnboarded, forKey: onboardedKey)
        }
    }

    @Published var checklistItems: [ChecklistItem] {
        didSet {
            saveChecklist()
        }
    }

    var selectedState: StateVotingInfo? {
        guard let id = selectedStateId else { return nil }
        return VotingDataStore.state(for: id)
    }

    private init() {
        self.selectedStateId = UserDefaults.standard.string(forKey: stateKey)
        self.hasOnboarded = UserDefaults.standard.bool(forKey: onboardedKey)
        self.checklistItems = UserPreferences.loadChecklist()
    }

    func completeOnboarding(stateId: String) {
        selectedStateId = stateId
        hasOnboarded = true
    }

    func changeState(stateId: String) {
        selectedStateId = stateId
    }

    func resetChecklist() {
        checklistItems = ChecklistItem.defaultItems
    }

    func toggleChecklistItem(id: String) {
        if let index = checklistItems.firstIndex(where: { $0.id == id }) {
            checklistItems[index].isCompleted.toggle()
        }
    }

    // MARK: - Persistence

    private func saveChecklist() {
        if let data = try? JSONEncoder().encode(checklistItems) {
            UserDefaults.standard.set(data, forKey: checklistKey)
        }
    }

    private static func loadChecklist() -> [ChecklistItem] {
        guard let data = UserDefaults.standard.data(forKey: "bb_checklist_items"),
              let items = try? JSONDecoder().decode([ChecklistItem].self, from: data) else {
            return ChecklistItem.defaultItems
        }
        return items
    }
}
