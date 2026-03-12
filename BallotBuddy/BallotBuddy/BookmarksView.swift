import SwiftUI

// MARK: - BookmarksView
// Displays saved bookmarks in a native SwiftUI List.
// Supports swipe-to-delete, timestamps, and tap-to-load.

struct BookmarksView: View {
    @ObservedObject var bookmarkStore: BookmarkStore
    @ObservedObject var webViewModel: WebViewModel
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkStore.bookmarks.isEmpty {
                    emptyState
                } else {
                    bookmarkList
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bookmark.slash")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No Bookmarks Yet")
                .font(.title2.bold())
            Text("Tap the bookmark icon while viewing a page to save it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Bookmark List

    private var bookmarkList: some View {
        List {
            ForEach(bookmarkStore.bookmarks) { bookmark in
                Button {
                    if let url = URL(string: bookmark.url) {
                        webViewModel.load(url: url)
                    }
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bookmark.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(bookmark.url)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Text(dateFormatter.string(from: bookmark.savedAt))
                            .font(.system(size: 11))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { offsets in
                bookmarkStore.removeBookmarks(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }
}
