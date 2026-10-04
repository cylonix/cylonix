// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import FileProvider
import Foundation

/// Enumerates a local folder. The sync anchor is the previous listing
/// itself (identifier → version), so change enumeration is a diff against
/// the current directory contents and needs no persistent state.
final class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    private let container: NSFileProviderItemIdentifier
    private let root: URL

    init(container: NSFileProviderItemIdentifier, root: URL) {
        self.container = container
        self.root = root
    }

    func invalidate() {}

    private func currentItems() -> [FileProviderItem] {
        if container == .workingSet {
            return FileProviderStore.allItems(root: root)
        }
        return FileProviderStore.children(of: container, root: root)
    }

    private func snapshot(_ items: [FileProviderItem]) -> NSFileProviderSyncAnchor {
        var map: [String: String] = [:]
        for item in items {
            map[item.itemIdentifier.rawValue] = item.versionTag
        }
        let data = (try? JSONSerialization.data(withJSONObject: map)) ?? Data()
        return NSFileProviderSyncAnchor(data)
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        if container == .trashContainer {
            observer.finishEnumerating(upTo: nil)
            return
        }
        observer.didEnumerate(currentItems())
        observer.finishEnumerating(upTo: nil)
    }

    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        guard let previous = (try? JSONSerialization.jsonObject(with: anchor.rawValue)) as? [String: String] else {
            observer.finishEnumeratingWithError(NSFileProviderError(.syncAnchorExpired))
            return
        }
        let items = currentItems()
        var updated: [FileProviderItem] = []
        var seen = Set<String>()
        for item in items {
            let id = item.itemIdentifier.rawValue
            seen.insert(id)
            if previous[id] != item.versionTag {
                updated.append(item)
            }
        }
        let deleted = previous.keys.filter { !seen.contains($0) }.map { NSFileProviderItemIdentifier($0) }
        if !updated.isEmpty { observer.didUpdate(updated) }
        if !deleted.isEmpty { observer.didDeleteItems(withIdentifiers: deleted) }
        observer.finishEnumeratingChanges(upTo: snapshot(items), moreComing: false)
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(snapshot(currentItems()))
    }
}
