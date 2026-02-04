import SwiftUI

struct ContentView: View {
    @StateObject private var preferences = UserPreferences.shared

    var body: some View {
        Group {
            if preferences.hasOnboarded {
                MainTabView(preferences: preferences)
            } else {
                OnboardingView(preferences: preferences)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: preferences.hasOnboarded)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @ObservedObject var preferences: UserPreferences
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(preferences: preferences)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            ChecklistView(preferences: preferences)
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Checklist")
                }
                .tag(1)

            RemindersView(preferences: preferences)
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Reminders")
                }
                .tag(2)
        }
        .tint(AppTheme.accentBlue)
        .onAppear {
            // Style the tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppTheme.deepNavy)

            let normalAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.5)
            ]
            let selectedAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(AppTheme.accentBlue)
            ]

            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.accentBlue)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
