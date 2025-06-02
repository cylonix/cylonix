#if os(iOS)
    // import MobileCoreServices
    // import Photos
    // import Social
    import UIKit
    typealias FileDropHostingController = UIHostingController<FileDropView>
#else
    import Cocoa
    typealias FileDropHostingController = NSHostingController<FileDropView>
#endif
import os.log
import SwiftUI
import UniformTypeIdentifiers

public func debugLog(_ message: String, function: String = #function) {
    let logger = OSLog(subsystem: "io.cylonix.sase.shareExtension", category: "ShareViewController")
    os_log("[%{public}@] %{public}@", log: logger, type: .debug, function, "CylonixShareView: \(message)")
    #if DEBUG
        print("CylonixShareView: ShareViewController: \(function): \(message)")
    #endif
}

#if os(iOS)
    class ShareViewController: UIViewController {
        private var hostingController: FileDropHostingController?
        private var sharedFiles: [SharedFile] = []
        private var fileInfos: [[String: Any]] = []
        private var unSupportedTypes = Set<String>()
        private var pending: Int = 0
    }

#elseif os(macOS)
    class ShareViewController: NSViewController {
        private var hostingController: FileDropHostingController?
        private var sharedFiles: [SharedFile] = []
        private var fileInfos: [[String: Any]] = []
        private var unSupportedTypes = Set<String>()
        private var pending: Int = 0

        override var nibName: NSNib.Name? { .init("ShareViewController") }
        override func loadView() {
            view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 800))
        }
    }
#endif

extension ShareViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        processReceivedItems()
    }

    private func finishRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func processReceivedItems() {
        let attachments = (extensionContext?.inputItems.first as? NSExtensionItem)?
            .attachments ?? []

        pending = attachments.count
        debugLog("Received items: \(pending)")
        guard pending > 0 else {
            finishRequest()
            return
        }
        fileInfos = []
        sharedFiles = []

        #if os(iOS)
            let types: [UTType] = [
                UTType.video,
                UTType.audio,
                UTType.image,
                UTType.fileURL,
            ]
        #else
            let types: [UTType] = [
                UTType.fileURL,
            ]
        #endif

        for attachment in attachments {
            debugLog("Processing attachment \(attachment)")
            var supported = false
            for type in types {
                if attachment.hasItemConformingToTypeIdentifier(type.identifier) {
                    handleSharedFileItem(attachment, type.identifier)
                    supported = true
                    break
                } else {
                    debugLog("Attachment does not conform to \(type.identifier)")
                }
            }
            if supported { continue }
            unSupportedTypes.formUnion(attachment.registeredTypeIdentifiers)

            debugLog("Attachment type not supported: \(attachment.registeredTypeIdentifiers)")
            decrementPendingAndMaybeShow()
        }
    }

    private func handleSharedFileItem(_ attachment: NSItemProvider, _ identifier: String) {
        debugLog("handleSharedFileItem with identifier \(identifier)")
        attachment.loadItem(forTypeIdentifier: identifier, options: nil) { data, error in
            defer { self.decrementPendingAndMaybeShow() }
            if let error = error {
                debugLog("Error loading item: \(error)")
                return
            }
            guard let data = data else {
                debugLog("No data received")
                return
            }

            debugLog("Loaded item type: \(type(of: data))")

            if let url = data as? URL {
                self.copyToTempFolder(url)
                return
            }

            #if os(iOS)
                // Handle UIImage type
                if let image = data as? UIImage {
                    guard let tempFolder = sharedTempFolder() else {
                        debugLog("Failed to locate shared temp folder")
                        return
                    }

                    let fileName = "\(UUID().uuidString).png"
                    let destURL = tempFolder.appendingPathComponent(fileName)

                    if let imageData = image.pngData() {
                        do {
                            try imageData.write(to: destURL)
                            debugLog("Saved image to \(destURL.path)")
                            self.appendSharedFile(fileName, destURL)
                        } catch {
                            debugLog("Failed to save image: \(error)")
                        }
                    }
                    return
                }
            #endif

            // Convert NSData to URL string then URL
            if let data = data as? Data, let urlString = String(data: data, encoding: .utf8),
               let url = URL(string: urlString)
            {
                self.copyToTempFolder(url)
            } else {
                debugLog("Failed to create URL from data: \(data)")
            }
        }
    }

    private func copyToTempFolder(_ url: URL) {
        guard let tempFolder = sharedTempFolder() else {
            debugLog("Failed to locate shared temp folder")
            return
        }
        let destURL = tempFolder.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.copyItem(at: url, to: destURL)
            debugLog("Copied \(url.path) → \(destURL.path)")
            appendSharedFile(url.lastPathComponent, destURL)
        } catch {
            debugLog("Failed to copy file into temp folder: \(error)")
            return
        }
    }

    private func decrementPendingAndMaybeShow() {
        DispatchQueue.main.async {
            self.pending -= 1
            if self.pending == 0 { self.showFileDropView() }
        }
    }

    private func appendSharedFile(_ name: String, _ fileURL: URL) {
        debugLog("Copied \(fileURL.path)")
        let size = (try? FileManager.default
            .attributesOfItem(atPath: fileURL.path)[.size]
            as? Int64) ?? 0
        let info: [String: Any] = [
            "path": fileURL.path,
            "name": name,
            "size": size,
        ]
        fileInfos.append(info)
        sharedFiles.append(
            SharedFile(path: fileURL.path,
                       name: name,
                       size: size)
        )
    }

    // If there is no file accepted to share, show a message
    private func showFileDropView() {
        debugLog("showFileDropView with \(sharedFiles.count) files")

        hostingController?.removeFromParent()
        hostingController?.view.removeFromSuperview()

        let fileDropView = FileDropView(
            sharedFiles: sharedFiles,
            unSupportedTypes: unSupportedTypes,
            onCancel: { [weak self] in self?.finishRequest() }
        )
        let hc = FileDropHostingController(rootView: fileDropView)
        addChild(hc)
        hc.view.frame = view.bounds
        #if os(iOS)
            hc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        #else
            hc.view.autoresizingMask = [.width, .height]
        #endif
        view.addSubview(hc.view)
        #if os(macOS)
            view.layoutSubtreeIfNeeded()
        #else
            view.layoutIfNeeded()
        #endif
        hostingController = hc
    }

    private func sendToMainApp(fileInfos: [[String: Any]]) {
        debugLog("SendToMainApp: \(fileInfos)")

        guard let appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String),
              let sharedDefaults = UserDefaults(suiteName: appGroupId)
        else {
            debugLog("Failed to get shared defaults")
            finishRequest()
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

        finishRequest()
    }
}
