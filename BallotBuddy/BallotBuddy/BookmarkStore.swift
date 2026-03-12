import Foundation

// MARK: - Bookmark Model

struct Bookmark: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var url: String
    var savedAt: Date

    init(title: String, url: String) {
        self.id = UUID()
        self.title = title.isEmpty ? url : title
        self.url = url
        self.savedAt = Date()
    }
}

// MARK: - Bookmark Store

class BookmarkStore: ObservableObject {
    @Published private(set) var bookmarks: [Bookmark] = []

    private let storageKey = "bb_bookmarks"

    init() {
        load()
    }

    func addBookmark(title: String, url: String) {
        guard !bookmarks.contains(where: { $0.url == url }) else { return }
        let bookmark = Bookmark(title: title, url: url)
        bookmarks.insert(bookmark, at: 0)
        save()
    }

    func removeBookmark(url: String) {
        bookmarks.removeAll { $0.url == url }
        save()
    }

    func removeBookmarks(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        save()
    }

    func isBookmarked(url: String) -> Bool {
        bookmarks.contains { $0.url == url }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([Bookmark].self, from: data) else { return }
        bookmarks = items
    }
}
