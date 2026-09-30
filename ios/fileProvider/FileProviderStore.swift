// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import FileProvider
import Foundation
import UniformTypeIdentifiers

/// The folder this provider exposes: the app group's "File Provider
/// Storage" directory, which is where the (non-replicated) File Provider
/// API requires provided files to live. The network extension finalizes
/// plain File Drop receipts there (WireGuardAdapter
/// .deliverPlainFilesToSharedDownloads). Keep the folder name in sync with
/// SharedDownloads in PacketTunnelMessage.swift, which the app and the
/// extension compile but this target does not.
enum FileProviderStore {
    static var root: URL {
        let url = NSFileProviderManager.default.documentStorageURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Item identifiers are paths relative to the root, so they survive
    /// the provider being relaunched and need no database.
    static func url(for identifier: NSFileProviderItemIdentifier, root: URL) -> URL {
        if identifier == .rootContainer {
            return root
        }
        return root.appendingPathComponent(identifier.rawValue)
    }

    static func identifier(for url: URL, root: URL) -> NSFileProviderItemIdentifier {
        let rootPath = root.standardizedFileURL.resolvingSymlinksInPath().path
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        guard path.hasPrefix(rootPath), path.count > rootPath.count else {
            return .rootContainer
        }
        var relative = String(path.dropFirst(rootPath.count))
        if relative.hasPrefix("/") { relative.removeFirst() }
        return NSFileProviderItemIdentifier(relative)
    }

    static func parentIdentifier(of identifier: NSFileProviderItemIdentifier) -> NSFileProviderItemIdentifier {
        if identifier == .rootContainer { return .rootContainer }
        let parent = (identifier.rawValue as NSString).deletingLastPathComponent
        return parent.isEmpty ? .rootContainer : NSFileProviderItemIdentifier(parent)
    }

    private static let keys: [URLResourceKey] = [
        .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey,
    ]

    /// Recursive listing of every item under root.
    static func allItems(root: URL) -> [FileProviderItem] {
        var items: [FileProviderItem] = []
        guard let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
        ) else {
            return items
        }
        for case let url as URL in enumerator where !isPlaceholder(url) {
            if let item = try? FileProviderItem(url: url, root: root) {
                items.append(item)
            }
        }
        return items
    }

    static func children(of container: NSFileProviderItemIdentifier, root: URL) -> [FileProviderItem] {
        let dir = url(for: container, root: root)
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return urls.filter { !isPlaceholder($0) }.compactMap { try? FileProviderItem(url: $0, root: root) }
    }

    /// The system writes "<name>.icloud" placeholders next to files; they
    /// are not items.
    static func isPlaceholder(_ url: URL) -> Bool {
        url.lastPathComponent.hasPrefix(".") || url.pathExtension == "icloud"
    }

    static func uniqueURL(in dir: URL, name: String) -> URL {
        let fm = FileManager.default
        var candidate = dir.appendingPathComponent(name)
        if !fm.fileExists(atPath: candidate.path) { return candidate }
        let ext = (name as NSString).pathExtension
        let base = (name as NSString).deletingPathExtension
        for i in 1 ... 1000 {
            let n = ext.isEmpty ? "\(base) (\(i))" : "\(base) (\(i)).\(ext)"
            candidate = dir.appendingPathComponent(n)
            if !fm.fileExists(atPath: candidate.path) { return candidate }
        }
        return dir.appendingPathComponent("\(UUID().uuidString)-\(name)")
    }
}

final class FileProviderItem: NSObject, NSFileProviderItem {
    let itemIdentifier: NSFileProviderItemIdentifier
    let parentItemIdentifier: NSFileProviderItemIdentifier
    let filename: String
    let contentType: UTType
    let documentSize: NSNumber?
    let contentModificationDate: Date?
    let creationDate: Date?
    private let isFolder: Bool

    /// The root of the provider, shown in Files under the extension's name.
    init(rootNamed name: String) {
        itemIdentifier = .rootContainer
        parentItemIdentifier = .rootContainer
        filename = name
        contentType = .folder
        documentSize = nil
        contentModificationDate = nil
        creationDate = nil
        isFolder = true
    }

    init(url: URL, root: URL) throws {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey])
        isFolder = values.isDirectory ?? false
        itemIdentifier = FileProviderStore.identifier(for: url, root: root)
        parentItemIdentifier = FileProviderStore.parentIdentifier(of: itemIdentifier)
        filename = url.lastPathComponent
        contentType = isFolder ? .folder : (UTType(filenameExtension: url.pathExtension) ?? .data)
        documentSize = isFolder ? nil : NSNumber(value: values.fileSize ?? 0)
        contentModificationDate = values.contentModificationDate
        creationDate = values.creationDate
    }

    var typeIdentifier: String { contentType.identifier }

    var capabilities: NSFileProviderItemCapabilities {
        if isFolder {
            return [.allowsReading, .allowsContentEnumerating, .allowsAddingSubItems,
                    .allowsDeleting, .allowsRenaming, .allowsReparenting]
        }
        return [.allowsReading, .allowsWriting, .allowsDeleting, .allowsRenaming, .allowsReparenting]
    }

    // Everything is local: no download badge, nothing to upload.
    var isDownloaded: Bool { true }
    var isMostRecentVersionDownloaded: Bool { true }
    var isUploaded: Bool { true }

    /// Version string used by the enumerator's sync anchor.
    var versionTag: String {
        "\(contentModificationDate?.timeIntervalSince1970 ?? 0)-\(documentSize?.int64Value ?? 0)"
    }

    var versionIdentifier: Data? { Data(versionTag.utf8) }
}
