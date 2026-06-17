// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import UserNotifications
#if os(iOS)
    import BackgroundTasks
    import Photos
    import UniformTypeIdentifiers
#endif

struct WaitingFile: Codable {
    let ID: String?
    let Name: String
    let Size: Int64
}

struct FilesWaiting: Codable {
    let Dir: String
    let Files: [WaitingFile]
}

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private static let transferIDSidecarSuffix = ".cylonix-transfer-id"
    private static let peerMessageNotificationLedgerKey = "PeerMessageNotifiedTransferIDs"

    // Serial queue for file processing. SceneDelegate calls in on the main
    // thread; the Photos import below blocks on authorization and
    // performChangesAndWait, so the body must run off the main thread.
    private let processingQueue = DispatchQueue(
        label: "io.cylonix.sase.fileProcessingQueue",
        qos: .utility
    )

    func processFilesFromSharedContainer(completion: @escaping (Bool) -> Void) {
        processingQueue.async {
            self.processFilesFromSharedContainerLocked(completion: completion)
        }
    }

    private func processFilesFromSharedContainerLocked(completion: @escaping (Bool) -> Void) {
        wg_log(.info, message: "Processing files from shared container")

        guard let appGroupId = FileManager.appGroupId,
                let groupDefaults = UserDefaults(suiteName: appGroupId) else {
            wg_log(.error, message: "Unable to access shared UserDefaults")
            completion(false)
            return
        }
        groupDefaults.synchronize()
        guard let filesWaitingJson = groupDefaults.string(forKey: PacketTunnelUserDefaultsKey.filesWaiting) else {
            wg_log(.error, message: "No files waiting details found")
            completion(false)
            return
        }
        guard let jsonData = filesWaitingJson.data(using: .utf8),
              let filesWaiting = try? JSONDecoder().decode(FilesWaiting.self, from: jsonData)
        else {
            wg_log(.error, message: "invalid file waiting details JSON \(filesWaitingJson)")
            completion(false)
            return
        }

        #if os(iOS)
            let destinationURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("Downloads")
        #endif
        // macOS computes a per-file destination inside the loop below:
        // peer-message attachments go to the app-managed peer_messaging store
        // (chat-accessible, never the user's Downloads); plain Taildrop drops
        // go to ~/Downloads/Cylonix.

        do {
            #if os(iOS)
                try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            #endif

            let sourceDir = URL(fileURLWithPath: filesWaiting.Dir)
            var processedFiles: [String] = []
            var peerMessagingTransferIDs: [String] = []
            var nonPeerMessagingFiles: [String] = []
            var photoLibrarySavedFiles: [String] = []

            for file in filesWaiting.Files {
                let sourceURL = sourceDir.appendingPathComponent(file.Name)

                if !FileManager.default.fileExists(atPath: sourceURL.path) {
                    wg_log(.error, message: "Source file not found: \(sourceURL.path)")
                    continue
                }

                let transferID = resolvedTransferID(for: file, in: sourceDir)

                #if os(iOS)
                    // AirDrop parity: plain drops (no peer-message transfer
                    // ID) of photos and videos go straight into the Photos
                    // library instead of the app's Downloads folder. Chat
                    // attachments keep the Downloads path so message bubbles
                    // can reference the saved file. On permission denial or
                    // import failure the file falls through to the regular
                    // Downloads move below.
                    if (transferID ?? "").isEmpty,
                       isPhotoLibraryCandidate(file.Name),
                       saveToPhotoLibrary(fileURL: sourceURL, name: file.Name)
                    {
                        cleanupTransferIDSidecar(for: file, in: sourceDir)
                        processedFiles.append(file.Name)
                        photoLibrarySavedFiles.append(file.Name)
                        continue
                    }
                #endif

                #if os(macOS)
                    // Route by kind on macOS. Peer-message attachments
                    // (transferID present) land in the app-managed
                    // peer_messaging store so chat bubbles can read them and are
                    // deliberately kept OUT of the user's Downloads; the Flutter
                    // side relocates them into the profile-scoped managed dir.
                    // Plain Taildrop drops go to ~/Downloads/Cylonix.
                    let destinationURL: URL
                    if let transferID, !transferID.isEmpty {
                        destinationURL = FileManager.default.urls(
                            for: .applicationSupportDirectory, in: .userDomainMask
                        )[0]
                        .appendingPathComponent("peer_messaging", isDirectory: true)
                        .appendingPathComponent("incoming", isDirectory: true)
                    } else {
                        destinationURL = FileManager.default.urls(
                            for: .downloadsDirectory, in: .userDomainMask
                        )[0].appendingPathComponent("Cylonix", isDirectory: true)
                    }
                    do {
                        try FileManager.default.createDirectory(
                            at: destinationURL, withIntermediateDirectories: true)
                    } catch {
                        wg_log(.error, message: "Failed to create destination \(destinationURL.path): \(error)")
                        continue
                    }
                #endif

                if let uniqueName = getUniqueFileName(originalName: file.Name, at: destinationURL) {
                    let destinationFileURL = destinationURL.appendingPathComponent(uniqueName)
                    do {
                        try FileManager.default.moveItem(at: sourceURL, to: destinationFileURL)
                        if let transferID, !transferID.isEmpty {
                            wg_log(.info, message: "Peer attachment auto-saved: transferID=\(transferID) source=\(sourceURL.path) destination=\(destinationFileURL.path)")
                            saveAutoSavedFilePath(
                                destinationFileURL.path,
                                forTransferID: transferID,
                                defaults: groupDefaults
                            )
                            peerMessagingTransferIDs.append(transferID)
                        } else {
                            wg_log(.debug, message: "Auto-saved file without transferID: name=\(file.Name) destination=\(destinationFileURL.path)")
                            nonPeerMessagingFiles.append(uniqueName)
                        }
                        cleanupTransferIDSidecar(for: file, in: sourceDir)
                        processedFiles.append(uniqueName)
                    } catch {
                        wg_log(.error, message: "Failed to move file: \(error)")
                    }
                } else {
                    wg_log(.error, message: "Could not generate unique name for: \(file.Name)")
                }
            }

            if !processedFiles.isEmpty {
                markPeerMessagingTransfersNotified(peerMessagingTransferIDs, defaults: groupDefaults)
                if !photoLibrarySavedFiles.isEmpty {
                    notifyUserSavedToPhotos(files: photoLibrarySavedFiles)
                }
                if !nonPeerMessagingFiles.isEmpty {
                    notifyUserAirDropStyle(files: nonPeerMessagingFiles)
                } else if photoLibrarySavedFiles.isEmpty, !peerMessagingTransferIDs.isEmpty {
                    wg_log(.info, message: "Suppressing auto-save notification for peer messaging transfers: \(peerMessagingTransferIDs)")
                }
                wg_log(.info, message: "Processed files: \(processedFiles.joined(separator: ", "))")
                groupDefaults.atomicUpdate(forKey: "FilesWaiting") { currentValue in
                    if currentValue as? String == filesWaitingJson {
                        return nil
                    }
                    return currentValue
                }
            }
            completion(true)
        } catch {
            wg_log(.error, message: "Error processing files: \(error)")
            completion(false)
        }
    }

    #if os(iOS)
        // isPhotoLibraryCandidate reports whether a received file should be
        // imported into the Photos library, judged by filename extension
        // (the only type information Taildrop carries).
        private func isPhotoLibraryCandidate(_ name: String) -> Bool {
            let ext = (name as NSString).pathExtension
            guard !ext.isEmpty, let type = UTType(filenameExtension: ext) else {
                return false
            }
            return type.conforms(to: .image) || type.conforms(to: .movie)
        }

        // ensurePhotoLibraryAddAuthorization checks add-only Photos access,
        // prompting the user once if undetermined. Blocks the calling
        // (background) queue until the prompt resolves.
        private func ensurePhotoLibraryAddAuthorization() -> Bool {
            var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if status == .notDetermined {
                let semaphore = DispatchSemaphore(value: 0)
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                    status = newStatus
                    semaphore.signal()
                }
                semaphore.wait()
            }
            return status == .authorized || status == .limited
        }

        // saveToPhotoLibrary imports the file at fileURL into the Photos
        // library, moving it out of the staging directory on success.
        // Returns false (leaving the source file in place) when permission
        // is denied or Photos rejects the asset, so the caller can fall
        // back to the Downloads flow.
        private func saveToPhotoLibrary(fileURL: URL, name: String) -> Bool {
            guard ensurePhotoLibraryAddAuthorization() else {
                wg_log(.info, message: "Photos add access denied; saving \(name) to Downloads instead")
                return false
            }
            let ext = (name as NSString).pathExtension
            let isMovie = UTType(filenameExtension: ext)?.conforms(to: .movie) ?? false
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(
                        with: isMovie ? .video : .photo,
                        fileURL: fileURL,
                        options: options
                    )
                }
                wg_log(.info, message: "Imported \(name) into Photos library")
                return true
            } catch {
                wg_log(.error, message: "Photos import failed for \(name): \(error); saving to Downloads instead")
                return false
            }
        }
    #endif

    private func notifyUserSavedToPhotos(files: [String]) {
        let content = UNMutableNotificationContent()
        let previewsEnabled = currentNotificationPreviewEnabled()

        if previewsEnabled {
            content.title = files.count == 1 ? "Saved to Photos" : "\(files.count) items saved to Photos"
            content.body = files.joined(separator: ", ")
        } else {
            content.title = files.count == 1 ? "Saved to Photos" : "Items saved to Photos"
            content.body = "Open the Photos app to view."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            notificationCenter.add(request) { error in
                if let error = error {
                    wg_log(.error, message: "Failed to add Photos-saved notification: \(error)")
                }
            }
        }
    }

    private func notifyUserAirDropStyle(files: [String]) {
        let content = UNMutableNotificationContent()
        let previewsEnabled = currentNotificationPreviewEnabled()

        if previewsEnabled {
            if files.count == 1 {
                content.title = "File received and saved"
                content.body = files[0]
            } else {
                content.title = "\(files.count) Files received and saved"
                content.body = files.joined(separator: ", ")
            }
        } else {
            content.title = files.count == 1 ? "File received and saved" : "Files received and saved"
            content.body = "Open Cylonix to view file details."
        }

        content.sound = .default
        content.categoryIdentifier = "FILE_TRANSFER"

        #if os(iOS)
            let openActionTitle = "Show in Files"
        #else
            let openActionTitle = "Show in Downloads"
        #endif

        let openAction = UNNotificationAction(
            identifier: "OPEN_FOLDER",
            title: openActionTitle,
            options: [.foreground, .authenticationRequired]
        )

        let category = UNNotificationCategory(
            identifier: "FILE_TRANSFER",
            actions: [openAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([category])

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        wg_log(.info, message: "Scheduling user notification with content: \(content)")

        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            notificationCenter.add(request) { error in
                if let error = error {
                    wg_log(.error, message: "Failed to add user notification: \(error)")
                } else {
                    wg_log(.info, message: "User notification scheduled successfully")
                }
            }
        }
    }

}

extension BackgroundTaskManager {
    private func peerMessagingNotificationLedger(defaults: UserDefaults) -> [String: Double] {
        defaults.dictionary(forKey: Self.peerMessageNotificationLedgerKey) as? [String: Double] ?? [:]
    }

    private func currentNotificationPreviewEnabled() -> Bool {
        guard let appGroupId = FileManager.appGroupId,
              let defaults = UserDefaults(suiteName: appGroupId)
        else {
            return true
        }
        if defaults.object(forKey: PacketTunnelUserDefaultsKey.notificationPreviewEnabled) == nil {
            return true
        }
        return defaults.bool(forKey: PacketTunnelUserDefaultsKey.notificationPreviewEnabled)
    }

    private func markPeerMessagingTransfersNotified(
        _ transferIDs: [String],
        defaults: UserDefaults
    ) {
        guard !transferIDs.isEmpty else { return }
        var ledger = peerMessagingNotificationLedger(defaults: defaults)
        let now = Date().timeIntervalSince1970
        for transferID in transferIDs where !transferID.isEmpty {
            ledger[transferID] = now
        }
        defaults.set(ledger, forKey: Self.peerMessageNotificationLedgerKey)
        defaults.synchronize()
    }

    private func resolvedTransferID(for file: WaitingFile, in sourceDir: URL) -> String? {
        if let id = file.ID?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return id
        }
        let sidecarURL = sourceDir.appendingPathComponent(file.Name + Self.transferIDSidecarSuffix)
        guard let data = try? Data(contentsOf: sidecarURL),
              let id = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !id.isEmpty
        else {
            wg_log(.debug, message: "No transferID sidecar found for \(file.Name) at \(sidecarURL.path)")
            return nil
        }
        wg_log(.info, message: "Recovered transferID from sidecar for \(file.Name): \(id)")
        return id
    }

    private func cleanupTransferIDSidecar(for file: WaitingFile, in sourceDir: URL) {
        let sidecarURL = sourceDir.appendingPathComponent(file.Name + Self.transferIDSidecarSuffix)
        if FileManager.default.fileExists(atPath: sidecarURL.path) {
            do {
                try FileManager.default.removeItem(at: sidecarURL)
            } catch {
                wg_log(.error, message: "Failed to remove transferID sidecar at \(sidecarURL.path): \(error)")
            }
        }
    }

    private func autoSavedFilePaths(defaults: UserDefaults) -> [String: String] {
        defaults.dictionary(forKey: PacketTunnelUserDefaultsKey.autoSavedFilesByTransferID) as? [String: String] ?? [:]
    }

    private func saveAutoSavedFilePath(
        _ path: String,
        forTransferID transferID: String,
        defaults: UserDefaults
    ) {
        guard !transferID.isEmpty else { return }
        var mapping = autoSavedFilePaths(defaults: defaults)
        mapping[transferID] = path
        defaults.set(mapping, forKey: PacketTunnelUserDefaultsKey.autoSavedFilesByTransferID)
        defaults.synchronize()
    }

    private func pruneMissingAutoSavedFilePaths(defaults: UserDefaults) {
        let fileManager = FileManager.default
        let mapping = autoSavedFilePaths(defaults: defaults)
        let pruned = mapping.filter { fileManager.fileExists(atPath: $0.value) }
        if pruned.count != mapping.count {
            defaults.set(pruned, forKey: PacketTunnelUserDefaultsKey.autoSavedFilesByTransferID)
            defaults.synchronize()
        }
    }

    func consumeAutoSavedFilePaths() -> [String: String] {
        guard let appGroupId = FileManager.appGroupId,
              let groupDefaults = UserDefaults(suiteName: appGroupId)
        else {
            wg_log(.debug, message: "consumeAutoSavedFilePaths: no app group defaults available")
            return [:]
        }

        pruneMissingAutoSavedFilePaths(defaults: groupDefaults)
        let mapping = autoSavedFilePaths(defaults: groupDefaults)
        wg_log(.info, message: "consumeAutoSavedFilePaths: count=\(mapping.count) entries=\(mapping)")
        groupDefaults.removeObject(forKey: PacketTunnelUserDefaultsKey.autoSavedFilesByTransferID)
        groupDefaults.synchronize()
        return mapping
    }

    private func getUniqueFileName(originalName: String, at directory: URL) -> String? {
        let fileManager = FileManager.default
        let ext = (originalName as NSString).pathExtension
        let nameWithoutExt = (originalName as NSString).deletingPathExtension

        // Try original name first
        let originalPath = directory.appendingPathComponent(originalName).path
        if !fileManager.fileExists(atPath: originalPath) {
            return originalName
        }

        // Try with numbers
        for i in 1 ... 100 {
            let newName = "\(nameWithoutExt) (\(i)).\(ext)"
            let path = directory.appendingPathComponent(newName).path
            if !fileManager.fileExists(atPath: path) {
                return newName
            }
        }

        return nil // Give up after 100 attempts
    }
}
