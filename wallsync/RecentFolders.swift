import Foundation

struct RecentFolders {
    private static let key = "recentFolderBookmarks"
    private static let maxItems = 5

    static func add(url: URL) {
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)

            var existing = UserDefaults.standard.array(forKey: key) as? [Data] ?? []

            // Deduplicate by resolving existing bookmarks to their paths
            var resolvedPaths = [String]()
            var isStale: Bool = false
            for data in existing {
                if let u = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    resolvedPaths.append(u.path)
                }
            }

            // Remove any existing entry for this path
            if let index = resolvedPaths.firstIndex(of: url.path) {
                existing.remove(at: index)
            }

            // Prepend newest
            existing.insert(bookmark, at: 0)

            // Trim
            if existing.count > maxItems {
                existing = Array(existing.prefix(maxItems))
            }

            UserDefaults.standard.set(existing, forKey: key)
        } catch {
            print("Failed to create bookmark for URL: \(url) — \(error)")
        }
    }

    static func list() -> [URL] {
        guard let existing = UserDefaults.standard.array(forKey: key) as? [Data] else { return [] }
        var urls = [URL]()
        for data in existing {
            do {
                var isStale: Bool = false
                let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                urls.append(url)
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }
        return urls
    }

    static func loadFirstURL() -> URL? {
        guard let existing = UserDefaults.standard.array(forKey: key) as? [Data], let first = existing.first else { return nil }
        do {
            var isStale: Bool = false
            let url = try URL(resolvingBookmarkData: first, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    static func clearInvalidBookmarks() {
        guard let existing = UserDefaults.standard.array(forKey: key) as? [Data] else { return }
        var good = [Data]()
        for data in existing {
            var isStale: Bool = false   
            if let _ = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                good.append(data)
            }
        }
        UserDefaults.standard.set(good, forKey: key)
    }
}
