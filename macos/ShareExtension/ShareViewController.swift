import Cocoa
import os.log
import SwiftUI
import UniformTypeIdentifiers

public func debugLog(_ message: String, function: String = #function) {
    let logger = OSLog(subsystem: "io.cylonix.sase.CylonixShareExtension", category: "ShareViewController")
    os_log("[%{public}@] %{public}@", log: logger, type: .debug, function, "CylonixShareView: \(message)")
    #if DEBUG
        print("CylonixShareExtension: ShareViewController: \(function): \(message)")
    #endif
}

class ShareViewController: NSViewController {
    private var hostingController: NSHostingController<FileDropView>?
    private var sharedFiles: [SharedFile] = []

    override var nibName: NSNib.Name? {
        return NSNib.Name("ShareViewController")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 600))
    }

    override func viewDidLoad() {
        debugLog("ViewDidLoad")
        super.viewDidLoad()
        processReceivedItems()
    }

    private func processReceivedItems() {
        let attachments = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        var pendingAttachments = attachments.count
        var fileInfos: [[String: Any]] = []

        debugLog("Received items...\(pendingAttachments)")
        guard pendingAttachments > 0 else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        for attachment in attachments {
            debugLog("Processing attachment...\(attachment)")
            if attachment.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                    defer {
                        pendingAttachments -= 1
                        if pendingAttachments == 0 {
                            // self.sendToMainApp(fileInfos: fileInfos)
                            debugLog("All attachments processed. Loading file drop view...")
                            DispatchQueue.main.async {
                                debugLog("Loading file drop view...")
                                self.showFileDropView()
                            }
                        }
                    }
                    if let error = error {
                        debugLog("Error loading item: \(error)")
                        return
                    }
                    guard let data = data else {
                        debugLog("No data received")
                        return
                    }

                    debugLog("Loaded item type: \(type(of: data))")

                    // Convert NSData to URL string then URL
                    if let urlString = String(data: data as! Data, encoding: .utf8),
                       let url = URL(string: urlString)
                    {

                        guard let tempFolder = sharedTempFolder() else {
                            debugLog("Failed to locate shared temp folder")
                            return
                        }
                        let destURL = tempFolder.appendingPathComponent(UUID().uuidString)
                        do {
                            if FileManager.default.fileExists(atPath: destURL.path) {
                                try FileManager.default.removeItem(at: destURL)
                            }
                            try FileManager.default.copyItem(at: url, to: destURL)
                            debugLog("Copied \(url.path) → \(destURL.path)")
                        } catch {
                            debugLog("Failed to copy file into temp folder: \(error)")
                            return
                        }
                        let fileInfo: [String: Any] = [
                            "path": destURL.path,
                            "name": url.lastPathComponent,
                            "size": (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0,
                        ]
                        fileInfos.append(fileInfo)
                        let sharedFile = SharedFile(
                            path: destURL.path,
                            name: url.lastPathComponent,
                            size: (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
                        )
                        self.sharedFiles.append(sharedFile)
                    } else {
                        debugLog("Failed to create URL from data: \(data)")
                    }
                }
            } else {
                pendingAttachments -= 1
            }
        }
    }

    private func showFileDropView() {
        debugLog("ShowFileDropView: Started with \(sharedFiles.count) files")
        guard !sharedFiles.isEmpty else {
            extensionContext?.completeRequest(returningItems: nil)
            debugLog("No files to share")
            return
        }
        // Remove existing hosting controller if any
        hostingController?.removeFromParent()
        hostingController?.view.removeFromSuperview()

        let fileDropView = FileDropView(
            sharedFiles: sharedFiles,
            onCancel: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        )
        debugLog("Created FileDropView with \(sharedFiles.count) files")

        let hostingController = NSHostingController(rootView: fileDropView)
        addChild(hostingController)
        debugLog("Created hosting controller")

        // Set explicit frame for hosting controller view
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 480, height: 600)
        hostingController.view.autoresizingMask = [.width, .height]
        view.addSubview(hostingController.view)
        debugLog("Added hosting controller view to main view")

        // Force layout and display
        view.needsLayout = true
        view.needsDisplay = true
        view.layoutSubtreeIfNeeded()
    
        debugLog("Added hosting controller view with frame: \(hostingController.view.frame)")
        debugLog("Main view frame: \(view.frame)")

        self.hostingController = hostingController
    }

    private func sendToMainApp(fileInfos: [[String: Any]]) {
        debugLog("SendToMainApp: \(fileInfos)")

        guard let appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String),
              let sharedDefaults = UserDefaults(suiteName: appGroupId)
        else {
            debugLog("CylonixShareView: Failed to get shared defaults")
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: fileInfos)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                sharedDefaults.set(jsonString, forKey: "SharedFiles")
                sharedDefaults.synchronize()
                debugLog("Wrote shared files to UserDefaults")

                // Post notification to main app
                let center = CFNotificationCenterGetDarwinNotifyCenter()
                let name = "io.cylonix.sase.share.received" as CFString
                CFNotificationCenterPostNotification(center, CFNotificationName(name), nil, nil, true)
            }
        } catch {
            debugLog("Error serializing shared files: \(error)")
        }

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
