// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

#if os(iOS)
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
    os_log("[%{public}@] %{public}@", log: logger, type: .error, function, "CylonixShareView: \(message)")
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

        // Order matters: fileURL must be checked before url (fileURL is a
        // subtype of url). pdf also comes before url — Safari shares a viewed
        // PDF as document data alongside the page URL, and the document is
        // what the user means to share, not a .webloc. Likewise plainText is
        // checked as the canonical text identifier — most senders register
        // either plainText or one of its subtypes.
        let types: [UTType] = [
            UTType.video,
            UTType.audio,
            UTType.image,
            UTType.fileURL,
            UTType.pdf,
            UTType.url,
            UTType.plainText,
        ]

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

            // Fallback: accept any attachment whose concrete type can deliver
            // a data representation (documents other than the types above —
            // Keynote decks, vcards, archives — register only their own UTI).
            // Load by that concrete identifier so the saved file keeps the
            // right extension.
            if let identifier = attachment.registeredTypeIdentifiers.first(where: {
                UTType($0)?.conforms(to: .data) == true
            }) {
                debugLog("Falling back to data-conforming type \(identifier)")
                handleSharedFileItem(attachment, identifier)
                continue
            }

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

            debugLog("Loaded item type: \(type(of: data)) for identifier \(identifier)")

            // Web URL → save as .webloc (mimic AirDrop URL drop)
            if identifier == UTType.url.identifier {
                if let url = self.urlValue(from: data), !url.isFileURL {
                    self.writeWebloc(for: url, attachment: attachment)
                    return
                }
                // If somehow a file URL arrived under the url identifier,
                // fall through to the file-URL handling below.
            }

            // Plain text (and its subtypes) → save as .txt
            if let textType = UTType(identifier),
               textType.conforms(to: .text) || textType.conforms(to: .plainText)
            {
                if let text = self.textValue(from: data) {
                    self.writeTextFile(text, attachment: attachment)
                    return
                }
            }

            if let url = data as? URL, url.isFileURL {
                self.copyToTempFolder(url)
                return
            }
            if let nsurl = data as? NSURL, let url = nsurl as URL?, url.isFileURL {
                self.copyToTempFolder(url)
                return
            }

            #if os(iOS)
                if let image = data as? UIImage {
                    if let imageData = image.pngData() {
                        self.writeSharedData(imageData, attachment, UTType.png.identifier, fallbackExtension: "png")
                    } else {
                        debugLog("Failed to encode UIImage as PNG")
                    }
                    return
                }
            #elseif os(macOS)
                if let image = data as? NSImage {
                    guard let tiffData = image.tiffRepresentation,
                          let bitmap = NSBitmapImageRep(data: tiffData),
                          let imageData = bitmap.representation(using: .png, properties: [:])
                    else {
                        debugLog("Failed to encode NSImage as PNG")
                        return
                    }
                    self.writeSharedData(imageData, attachment, UTType.png.identifier, fallbackExtension: "png")
                    return
                }
            #endif

            if let bytes = data as? Data {
                if let url = self.fileURL(from: bytes) {
                    self.copyToTempFolder(url)
                    return
                }
                self.writeSharedData(bytes, attachment, identifier, fallbackExtension: "dat")
                return
            }

            debugLog("Unsupported loaded item value: \(type(of: data))")
        }
    }

    private func urlValue(from data: NSSecureCoding) -> URL? {
        if let url = data as? URL { return url }
        if let nsurl = data as? NSURL { return nsurl as URL }
        if let str = data as? String {
            return URL(string: str.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let ns = data as? NSString {
            return URL(string: (ns as String).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let bytes = data as? Data,
           let str = String(data: bytes, encoding: .utf8)
        {
            return URL(string: str.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private func textValue(from data: NSSecureCoding) -> String? {
        if let str = data as? String { return str }
        if let nsstr = data as? NSString { return nsstr as String }
        if let bytes = data as? Data { return String(data: bytes, encoding: .utf8) }
        return nil
    }

    private func writeWebloc(for url: URL, attachment: NSItemProvider) {
        guard let tempFolder = sharedTempFolder() else {
            debugLog("Failed to locate shared temp folder")
            return
        }
        let plist: [String: Any] = ["URL": url.absoluteString]
        let data: Data
        do {
            data = try PropertyListSerialization.data(
                fromPropertyList: plist, format: .xml, options: 0
            )
        } catch {
            debugLog("Failed to encode webloc plist: \(error)")
            return
        }

        let fileName = weblocFileName(for: url, attachment: attachment)
        let destURL = tempFolder.appendingPathComponent(fileName)
        do {
            try data.write(to: destURL)
            debugLog("Saved webloc to \(destURL.path)")
            appendSharedFile(fileName, destURL, kind: .url, text: url.absoluteString)
        } catch {
            debugLog("Failed to save webloc: \(error)")
        }
    }

    private func writeTextFile(_ text: String, attachment: NSItemProvider) {
        guard let tempFolder = sharedTempFolder() else {
            debugLog("Failed to locate shared temp folder")
            return
        }
        guard let data = text.data(using: .utf8) else {
            debugLog("Failed to encode shared text as UTF-8")
            return
        }
        let fileName = textFileName(for: text, attachment: attachment)
        let destURL = tempFolder.appendingPathComponent(fileName)
        do {
            try data.write(to: destURL)
            debugLog("Saved text to \(destURL.path)")
            appendSharedFile(fileName, destURL, kind: .text, text: text)
        } catch {
            debugLog("Failed to save text: \(error)")
        }
    }

    private func weblocFileName(for url: URL, attachment: NSItemProvider) -> String {
        let suggested = attachment.suggestedName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base: String
        if let suggested = suggested, !suggested.isEmpty {
            base = suggested
        } else if let host = url.host, !host.isEmpty {
            base = host
        } else {
            base = "Shared URL"
        }
        return ensureExtension(sanitize(base), ".webloc")
    }

    private func textFileName(for text: String, attachment: NSItemProvider) -> String {
        let suggested = attachment.suggestedName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base: String
        if let suggested = suggested, !suggested.isEmpty {
            base = suggested
        } else if let firstLine = text.components(separatedBy: .newlines)
            .first?.trimmingCharacters(in: .whitespacesAndNewlines),
            !firstLine.isEmpty
        {
            base = String(firstLine.prefix(50))
        } else {
            base = "Shared Text"
        }
        return ensureExtension(sanitize(base), ".txt")
    }

    private func sanitize(_ name: String) -> String {
        let illegal = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = name.unicodeScalars
            .map { illegal.contains($0) ? "-" : Character($0).description }
            .joined()
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Shared" : trimmed
    }

    private func ensureExtension(_ name: String, _ ext: String) -> String {
        name.lowercased().hasSuffix(ext.lowercased()) ? name : name + ext
    }

    private func fileURL(from data: Data) -> URL? {
        if let url = URL(dataRepresentation: data, relativeTo: nil), url.isFileURL {
            return url
        }
        if let urlString = String(data: data, encoding: .utf8),
           let url = URL(string: urlString),
           url.isFileURL
        {
            return url
        }
        return nil
    }

    private func writeSharedData(
        _ data: Data,
        _ attachment: NSItemProvider,
        _ identifier: String,
        fallbackExtension: String
    ) {
        guard let tempFolder = sharedTempFolder() else {
            debugLog("Failed to locate shared temp folder")
            return
        }

        let fileName = sharedFileName(for: attachment,
                                      identifier: identifier,
                                      data: data,
                                      fallbackExtension: fallbackExtension)
        let destURL = tempFolder.appendingPathComponent(fileName)

        do {
            try data.write(to: destURL)
            debugLog("Saved shared data to \(destURL.path)")
            appendSharedFile(fileName, destURL)
        } catch {
            debugLog("Failed to save shared data: \(error)")
        }
    }

    private func sharedFileName(
        for attachment: NSItemProvider,
        identifier: String,
        data: Data?,
        fallbackExtension: String
    ) -> String {
        let fileExtension = filenameExtension(for: identifier,
                                              data: data,
                                              fallbackExtension: fallbackExtension)
        if let suggestedName = attachment.suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !suggestedName.isEmpty
        {
            let lastPathComponent = URL(fileURLWithPath: suggestedName).lastPathComponent
            if URL(fileURLWithPath: lastPathComponent).pathExtension.isEmpty {
                return "\(lastPathComponent).\(fileExtension)"
            }
            return lastPathComponent
        }
        return "\(UUID().uuidString).\(fileExtension)"
    }

    private func filenameExtension(
        for identifier: String,
        data: Data?,
        fallbackExtension: String
    ) -> String {
        if let type = UTType(identifier),
           let fileExtension = type.preferredFilenameExtension,
           !fileExtension.isEmpty
        {
            return fileExtension
        }
        if let data = data {
            if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                return "png"
            }
            if data.starts(with: [0xFF, 0xD8, 0xFF]) {
                return "jpg"
            }
            if data.starts(with: [0x47, 0x49, 0x46]) {
                return "gif"
            }
            if data.starts(with: [0x49, 0x49, 0x2A, 0x00]) ||
                data.starts(with: [0x4D, 0x4D, 0x00, 0x2A])
            {
                return "tiff"
            }
        }
        return fallbackExtension
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

    private func appendSharedFile(
        _ name: String,
        _ fileURL: URL,
        kind: SharedFileKind = .file,
        text: String? = nil
    ) {
        debugLog("Copied \(fileURL.path) kind=\(kind.rawValue)")
        let size = (try? FileManager.default
            .attributesOfItem(atPath: fileURL.path)[.size]
            as? Int64) ?? 0
        let info: [String: Any] = [
            "path": fileURL.path,
            "name": name,
            "size": size,
            "kind": kind.rawValue,
        ]
        fileInfos.append(info)
        sharedFiles.append(
            SharedFile(path: fileURL.path,
                       name: name,
                       size: size,
                       kind: kind,
                       text: text)
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
            onCancel: { [weak self] in self?.finishRequest() },
            openHostApp: { [weak self] url in self?.openHostApp(url) ?? false }
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

    // MARK: - Hand-off to the containing app

    #if os(iOS)
        /// Opens the containing app. UIApplication.shared is off limits in an
        /// extension, but the hosting UIApplication sits at the top of the
        /// responder chain and its open(_:options:completionHandler:) works
        /// from a share extension (this target is not built extension-API-
        /// only, and the SDK no longer marks the method extension-unavailable).
        /// The walk must look for the application specifically: UIWindowScene
        /// sits below it in the chain and answers the same selector, but with
        /// a UISceneOpenExternalURLOptions parameter — calling it with a
        /// dictionary crashed the extension ("-[__NSDictionary0
        /// universalLinksOnly]") and left the share sheet stuck.
        /// Returns false when nothing could be asked to open; the app then
        /// picks the request up from disk the next time the user opens it.
        private func openHostApp(_ url: URL) -> Bool {
            var responder: UIResponder? = self
            while let current = responder {
                if let application = current as? UIApplication {
                    application.open(url, options: [:]) { success in
                        debugLog("UIApplication.open success=\(success)")
                    }
                    return true
                }
                responder = current.next
            }
            if let scene = view.window?.windowScene {
                scene.open(url, options: nil) { success in
                    debugLog("UIWindowScene.open success=\(success)")
                }
                return true
            }
            debugLog("No UIApplication or window scene able to open \(url)")
            return false
        }
    #elseif os(macOS)
        /// Opens the URL with the containing app specifically: both the App
        /// Store and the direct variant register the `cylonix` scheme, so a
        /// plain open could land in whichever one Launch Services prefers.
        /// The extension lives at <App>.app/Contents/PlugIns/<ext>.appex.
        private func openHostApp(_ url: URL) -> Bool {
            let appURL = Bundle.main.bundleURL
                .deletingLastPathComponent() // PlugIns
                .deletingLastPathComponent() // Contents
                .deletingLastPathComponent() // <App>.app
            guard appURL.pathExtension == "app" else {
                debugLog("Not inside an app bundle (\(appURL.path)); opening \(url) with the default handler")
                return NSWorkspace.shared.open(url)
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
                if let error = error {
                    debugLog("Failed to open \(url) with \(appURL.path): \(error)")
                }
            }
            return true
        }
    #endif

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
