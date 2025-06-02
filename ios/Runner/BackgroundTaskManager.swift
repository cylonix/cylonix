import Foundation
import UserNotifications
#if os(iOS)
    import BackgroundTasks
#endif

struct WaitingFile: Codable {
    let Name: String
    let Size: Int64
}

struct FilesWaiting: Codable {
    let Dir: String
    let Files: [WaitingFile]
}

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
 
    func processFilesFromSharedContainer(completion: @escaping (Bool) -> Void) {
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
        #else
            let destinationURL = FileManager.default.urls(
                for: .downloadsDirectory,
                in: .userDomainMask
            )[0]
        #endif

        do {
            #if os(iOS)
                try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            #endif

            let sourceDir = URL(fileURLWithPath: filesWaiting.Dir)
            var processedFiles: [String] = []

            for file in filesWaiting.Files {
                let sourceURL = sourceDir.appendingPathComponent(file.Name)

                if !FileManager.default.fileExists(atPath: sourceURL.path) {
                    wg_log(.error, message: "Source file not found: \(sourceURL.path)")
                    continue
                }

                if let uniqueName = getUniqueFileName(originalName: file.Name, at: destinationURL) {
                    let destinationFileURL = destinationURL.appendingPathComponent(uniqueName)
                    do {
                        try FileManager.default.moveItem(at: sourceURL, to: destinationFileURL)
                        processedFiles.append(uniqueName)
                    } catch {
                        wg_log(.error, message: "Failed to move file: \(error)")
                    }
                } else {
                    wg_log(.error, message: "Could not generate unique name for: \(file.Name)")
                }
            }

            if !processedFiles.isEmpty {
                notifyUserAirDropStyle(files: processedFiles)
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

    private func notifyUserAirDropStyle(files: [String]) {
        let content = UNMutableNotificationContent()

        if files.count == 1 {
            content.title = "File Received"
            content.body = files[0]
        } else {
            content.title = "\(files.count) Files Received"
            content.body = files.joined(separator: ", ")
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
