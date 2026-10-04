// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import FileProvider
import Foundation
import UniformTypeIdentifiers

/// Exposes the app group's File Provider Storage folder as a "Cylonix"
/// location in Files. Received files are written there by the network
/// extension while the app is suspended, so they are visible immediately
/// without opening Cylonix. Files may also add, rename, move and delete
/// items; those act directly on the folder.
///
/// This is the non-replicated provider (NSFileProviderExtension): the
/// files it serves are the real files, so Files shows them as downloaded.
/// The replicated API cannot express that on iOS.
final class FileProviderExtension: NSFileProviderExtension {
    private var root: URL { FileProviderStore.root }
    private var displayName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "Cylonix"
    }

    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        if identifier == .rootContainer {
            return FileProviderItem(rootNamed: displayName)
        }
        let url = FileProviderStore.url(for: identifier, root: root)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSFileProviderError(.noSuchItem)
        }
        return try FileProviderItem(url: url, root: root)
    }

    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        FileProviderStore.url(for: identifier, root: root)
    }

    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        FileProviderStore.identifier(for: url, root: root)
    }

    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        do {
            guard let identifier = persistentIdentifierForItem(at: url) else {
                throw NSFileProviderError(.noSuchItem)
            }
            let item = try self.item(for: identifier)
            let placeholder = NSFileProviderManager.placeholderURL(for: url)
            try FileManager.default.createDirectory(
                at: placeholder.deletingLastPathComponent(), withIntermediateDirectories: true)
            try NSFileProviderManager.writePlaceholder(at: placeholder, withMetadata: item)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    override func startProvidingItem(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        // The file already lives at its final URL.
        completionHandler(FileManager.default.fileExists(atPath: url.path) ? nil : NSFileProviderError(.noSuchItem))
    }

    override func stopProvidingItem(at url: URL) {
        // Keep the file; it is the only copy.
    }

    override func itemChanged(at url: URL) {
        signal()
    }

    private func signal() {
        NSFileProviderManager.default.signalEnumerator(for: .workingSet) { _ in }
        NSFileProviderManager.default.signalEnumerator(for: .rootContainer) { _ in }
    }

    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
        FileProviderEnumerator(container: containerItemIdentifier, root: root)
    }

    // MARK: - Actions

    override func importDocument(at fileURL: URL, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier,
                                 completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void)
    {
        let parent = FileProviderStore.url(for: parentItemIdentifier, root: root)
        let dest = FileProviderStore.uniqueURL(in: parent, name: fileURL.lastPathComponent)
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }
        do {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            var copyError: Error?
            NSFileCoordinator().coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { readURL in
                do { try FileManager.default.copyItem(at: readURL, to: dest) } catch { copyError = error }
            }
            if let copyError { throw copyError }
            let item = try FileProviderItem(url: dest, root: root)
            signal()
            completionHandler(item, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    override func createDirectory(withName directoryName: String, inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier,
                                  completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void)
    {
        let parent = FileProviderStore.url(for: parentItemIdentifier, root: root)
        let dest = FileProviderStore.uniqueURL(in: parent, name: directoryName)
        do {
            try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
            let item = try FileProviderItem(url: dest, root: root)
            signal()
            completionHandler(item, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    override func renameItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toName itemName: String,
                             completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void)
    {
        move(itemIdentifier, toParent: FileProviderStore.parentIdentifier(of: itemIdentifier),
             name: itemName, completionHandler: completionHandler)
    }

    override func reparentItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
                               toParentItemWithIdentifier parentItemIdentifier: NSFileProviderItemIdentifier,
                               newName: String?, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void)
    {
        let current = FileProviderStore.url(for: itemIdentifier, root: root)
        move(itemIdentifier, toParent: parentItemIdentifier,
             name: newName ?? current.lastPathComponent, completionHandler: completionHandler)
    }

    private func move(_ itemIdentifier: NSFileProviderItemIdentifier, toParent parentItemIdentifier: NSFileProviderItemIdentifier,
                      name: String, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void)
    {
        let current = FileProviderStore.url(for: itemIdentifier, root: root)
        let dest = FileProviderStore.url(for: parentItemIdentifier, root: root).appendingPathComponent(name)
        do {
            guard FileManager.default.fileExists(atPath: current.path) else {
                throw NSFileProviderError(.noSuchItem)
            }
            if dest.standardizedFileURL != current.standardizedFileURL {
                if FileManager.default.fileExists(atPath: dest.path) {
                    throw NSFileProviderError(.filenameCollision)
                }
                try FileManager.default.moveItem(at: current, to: dest)
                let oldPlaceholder = NSFileProviderManager.placeholderURL(for: current)
                try? FileManager.default.removeItem(at: oldPlaceholder)
            }
            let item = try FileProviderItem(url: dest, root: root)
            signal()
            completionHandler(item, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    override func deleteItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
                             completionHandler: @escaping (Error?) -> Void)
    {
        guard itemIdentifier != .rootContainer else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }
        let url = FileProviderStore.url(for: itemIdentifier, root: root)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try? FileManager.default.removeItem(at: NSFileProviderManager.placeholderURL(for: url))
            signal()
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}
