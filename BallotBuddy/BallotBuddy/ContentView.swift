import SwiftUI
import WebKit
import Combine

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

    // Shared WebView state — lifted here so WebViewScreen and BookmarksView
    // can both access the same WKWebView instance.
    @StateObject private var webViewModel = WebViewModel()
    @StateObject private var bookmarkStore = BookmarkStore()

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

            WebViewScreen(webViewModel: webViewModel, bookmarkStore: bookmarkStore)
                .tabItem {
                    Image(systemName: "globe")
                    Text("Browse")
                }
                .tag(3)
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

// MARK: - Search Coordinator (300 ms debounce via Combine)

private class SearchCoordinator: ObservableObject {
    @Published var query: String = ""
    @Published var debouncedQuery: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .assign(to: \.debouncedQuery, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - WebViewScreen
// Native shell around the WKWebView: NavigationStack, toolbar, search bar.

struct WebViewScreen: View {
    @ObservedObject var webViewModel: WebViewModel
    @ObservedObject var bookmarkStore: BookmarkStore

    @StateObject private var search = SearchCoordinator()
    @State private var showBookmarks = false
    @State private var showShare = false

    private var pageIsBookmarked: Bool {
        guard let url = webViewModel.currentURL else { return false }
        return bookmarkStore.isBookmarked(url: url.absoluteString)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Native Search Bar ──────────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search…", text: $search.query)
                        .textFieldStyle(.plain)
                        .submitLabel(.search)
                        .onSubmit {
                            webViewModel.evaluateSearch(search.query)
                        }

                    if !search.query.isEmpty {
                        Button {
                            search.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                // ── WebView ────────────────────────────────────────────
                BallotWebView(webViewModel: webViewModel)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle(webViewModel.currentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Share button (left / secondary side)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        shareCurrentURL()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(webViewModel.currentURL == nil)
                }

                // Bookmark + Bookmarks-list buttons (right side)
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: pageIsBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .disabled(webViewModel.currentURL == nil)

                    Button {
                        showBookmarks = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarksView(bookmarkStore: bookmarkStore, webViewModel: webViewModel)
            }
        }
        // Debounced live-search: fires 300 ms after the user stops typing
        .onChange(of: search.debouncedQuery) { newValue in
            guard !newValue.isEmpty else { return }
            webViewModel.evaluateSearch(newValue)
        }
    }

    // MARK: - Private helpers

    private func toggleBookmark() {
        guard let url = webViewModel.currentURL else { return }
        if pageIsBookmarked {
            bookmarkStore.removeBookmark(url: url.absoluteString)
        } else {
            let title = webViewModel.currentTitle.isEmpty
                ? url.absoluteString
                : webViewModel.currentTitle
            bookmarkStore.addBookmark(title: title, url: url.absoluteString)
        }
    }

    /// Presents the native iOS share sheet for the current page URL.
    private func shareCurrentURL() {
        guard let url = webViewModel.currentURL else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else { return }

        // Required for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(
                x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        rootVC.present(activityVC, animated: true)
    }
}

// MARK: - BallotWebView
// Minimal UIViewRepresentable — returns the shared WKWebView from WebViewModel.
// All configuration, delegates, and NativeFeaturesBridge are managed by WebViewModel.

struct BallotWebView: UIViewRepresentable {
    @ObservedObject var webViewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        webViewModel.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed — WebViewModel drives all state changes.
    }
}
