// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause
//
// CylonixNotifier: a background LaunchAgent that surfaces direct-mode
// Taildrop "file received" and peer-message events as macOS user
// notifications.
//
// Why this exists: the cylonixd LaunchDaemon runs as root with no
// Aqua/WindowServer session, so UNUserNotificationCenter inside it
// would not post banners. Cylonix.app already handles this when open,
// but users routinely close the app — this agent runs in the user's
// GUI session and posts banners regardless of app state.

import Cocoa
import Foundation
import UserNotifications

private let socketPath = "/var/run/cylonix/cylonixd.sock"
// mask=256 is ipn.NotifyRateLimit: the daemon coalesces "boring" notifies
// (NetMap/Engine only) to one every few seconds instead of forwarding each
// one. CylonixDirectFileReceived is a "notable" field (ipnlocal/bus.go
// isNotableNotify) and is still delivered immediately. Without this the
// control plane's netmap churn arrives here as a full ~140KB NetMap every
// couple of seconds that we never use.
private let watchPath  = "/localapi/v0/watch-ipn-bus?mask=256"
private let httpHost   = "local-tailscaled.sock"

final class NotifierApp: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // Request full (not provisional) authorization. Provisional auth is
        // auto-granted but delivers quietly: notifications land in
        // Notification Center with no banner or sound, so file arrivals
        // look like they were never received. The one-time Allow prompt is
        // worth the prominent banners.
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                NSLog("cylonix-notifier: requestAuthorization error: \(error)")
            }
            NSLog("cylonix-notifier: authorization granted=\(granted)")
        }
        Thread.detachNewThread { [weak self] in
            self?.streamForever()
        }
    }

    // Show banners even when (notionally) "foreground" — we have no UI, but
    // the system still consults this delegate.
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Open the file (or the containing folder) when the user taps the banner.
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        let userInfo = response.notification.request.content.userInfo
        if let conversationID = userInfo["conversation_id"] as? String, !conversationID.isEmpty {
            activateApp()
            return
        }
        guard let path = userInfo["path"] as? String, !path.isEmpty else { return }
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }

    // MARK: - watch-ipn-bus reader

    private func streamForever() {
        var backoff: useconds_t = 1_000_000 // 1s
        while true {
            let fd = openSocket()
            if fd < 0 {
                usleep(backoff)
                backoff = min(backoff * 2, 30_000_000)
                continue
            }
            backoff = 1_000_000
            sendRequest(fd: fd)
            readStream(fd: fd)
            close(fd)
            // Daemon restart, EOF, etc — wait briefly and reconnect.
            usleep(2_000_000)
        }
    }

    private func openSocket() -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        if fd < 0 { return -1 }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8)
        withUnsafeMutableBytes(of: &addr.sun_path) { raw in
            let buf = raw.bindMemory(to: UInt8.self)
            for i in 0..<pathBytes.count { buf[i] = pathBytes[i] }
            buf[pathBytes.count] = 0
        }
        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        let rc = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sp in
                connect(fd, sp, size)
            }
        }
        if rc < 0 {
            close(fd)
            return -1
        }
        return fd
    }

    private func sendRequest(fd: Int32) {
        let req = "GET \(watchPath) HTTP/1.1\r\nHost: \(httpHost)\r\nUser-Agent: cylonix-notifier/1\r\nConnection: close\r\n\r\n"
        let bytes = Array(req.utf8)
        var total = 0
        while total < bytes.count {
            let n = bytes.withUnsafeBufferPointer { ptr -> Int in
                send(fd, ptr.baseAddress!.advanced(by: total), bytes.count - total, 0)
            }
            if n <= 0 { return }
            total += n
        }
    }

    private func readStream(fd: Int32) {
        var carry = Data()
        var headersConsumed = false
        var chunkBuf = [UInt8](repeating: 0, count: 32 * 1024)
        while true {
            // Every iteration gets its own autorelease pool. This loop runs
            // on a detached thread and never returns, so the thread-level
            // pool is never drained: every autoreleased temporary created
            // below (Data/NSData bridging, the JSON parser and the object
            // tree it returns) would otherwise stay alive until the process
            // exits. Observed as ~8 MB/min of retained NSDictionary/CFString
            // growth, 1.3 GB after a few hours.
            let keepReading: Bool = autoreleasepool {
                let n = read(fd, &chunkBuf, chunkBuf.count)
                if n <= 0 { return false }
                carry.append(chunkBuf, count: n)
                if !headersConsumed {
                    if let r = carry.range(of: Data([0x0d, 0x0a, 0x0d, 0x0a])) {
                        carry.removeSubrange(carry.startIndex..<r.upperBound)
                        headersConsumed = true
                    } else {
                        return true
                    }
                }
                // The daemon may use chunked transfer encoding. Strip chunk
                // headers (hex line + CRLF) by scanning conservatively: any
                // non-JSON line is ignored.
                while let nlIdx = carry.firstIndex(of: 0x0a) {
                    let lineStart = carry.startIndex
                    var endIdx = nlIdx
                    // Trim a trailing CR if present.
                    if endIdx > lineStart, carry[carry.index(before: endIdx)] == 0x0d {
                        endIdx = carry.index(before: endIdx)
                    }
                    let line = carry.subdata(in: lineStart..<endIdx)
                    carry.removeSubrange(lineStart...nlIdx)
                    if line.isEmpty { continue }
                    handleLine(line)
                }
                return true
            }
            if !keepReading { return }
        }
    }

    // The top-level Notify keys this agent acts on. Checked as byte
    // substrings before parsing so NetMap/Prefs/Health messages are skipped
    // without ever building a JSON object tree for them.
    private static let fileReceivedKey = Data("\"CylonixDirectFileReceived\"".utf8)
    private static let peerMessageKey = Data("\"PeerMessageEvent\"".utf8)

    private func handleLine(_ data: Data) {
        // Only attempt JSON parse on lines that look like JSON objects.
        guard data.first == 0x7B /* '{' */ else { return }
        let hasFile = data.range(of: Self.fileReceivedKey) != nil
        let hasMessage = data.range(of: Self.peerMessageKey) != nil
        guard hasFile || hasMessage else { return }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        if hasFile, let dfr = obj["CylonixDirectFileReceived"] as? [String: Any] {
            let name = (dfr["name"] as? String) ?? ""
            let path = (dfr["path"] as? String) ?? ""
            let transferID = (dfr["transfer_id"] as? String) ?? ""
            DispatchQueue.main.async { [weak self] in
                self?.postNotification(name: name, path: path, transferID: transferID)
            }
        }
        if hasMessage, let event = obj["PeerMessageEvent"] as? [String: Any] {
            DispatchQueue.main.async { [weak self] in
                self?.handlePeerMessageEvent(event)
            }
        }
    }

    // MARK: - Peer messages

    /// Posts a banner for an incoming peer message, approval request or menu
    /// request, mirroring what the Network Extension does on the App Store
    /// build. Skipped when the user is already looking at that thread.
    private func handlePeerMessageEvent(_ event: [String: Any]) {
        guard let type = event["type"] as? String else { return }
        enum Kind { case message, approval, menu }
        let kind: Kind
        switch type {
        case "message_received": kind = .message
        case "approval_requested": kind = .approval
        case "menu_requested": kind = .menu
        default: return // sent/delivery/read/sync/warm events are not user-facing
        }
        let payload = event["payload"] as? [String: Any]
        // The app files an inbound message under the SENDING peer's stable id
        // (peer_messaging_service.dart, _canonicalConversationId), and that is
        // what it publishes as the open thread. The event's conversation_id
        // is the sender's own id for the thread, so it only serves as a
        // fallback when from_peer_id is missing.
        let fromPeerID = (payload?["from_peer_id"] as? String) ?? ""
        let conversationID = fromPeerID.isEmpty
            ? ((event["conversation_id"] as? String) ?? "")
            : fromPeerID
        if isConversationOpenInForeground(conversationID) {
            NSLog("cylonix-notifier: \(type) for open foreground thread \(conversationID), no banner")
            return
        }
        NSLog("cylonix-notifier: posting \(type) banner for thread \(conversationID)")
        let message = payload?["message"] as? [String: Any]
        let text = (message?["text"] as? String) ?? ""
        let messageID = (event["message_id"] as? String) ?? ""

        let content = UNMutableNotificationContent()
        if notificationPreviewEnabled {
            let title = (payload?["conversation_title"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                ?? (payload?["from_peer_name"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                ?? "Peer"
            switch kind {
            case .message:
                content.title = title
                content.body = text.isEmpty ? "Sent an attachment" : text
            case .approval:
                content.title = "\(title): approval needed"
                content.body = text.isEmpty ? "Open Cylonix to review this approval request." : text
            case .menu:
                content.title = "\(title): choice needed"
                content.body = text.isEmpty ? "Open Cylonix to respond." : text
            }
        } else {
            switch kind {
            case .message:
                content.title = "New peer message"
                content.body = "Open Cylonix to view this message."
            case .approval:
                content.title = "New approval request"
                content.body = "Open Cylonix to review this approval request."
            case .menu:
                content.title = "New menu request"
                content.body = "Open Cylonix to respond."
            }
        }
        content.sound = .default
        if !conversationID.isEmpty {
            content.threadIdentifier = conversationID
            content.userInfo = ["conversation_id": conversationID]
        }
        let id = messageID.isEmpty
            ? "cylonix-direct-pm-\(UUID().uuidString)"
            : "cylonix-direct-pm-\(messageID)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                NSLog("cylonix-notifier: add peer message notification failed: \(err)")
            }
        }
    }

    /// True when Cylonix.app is frontmost with this conversation's thread
    /// open: the user is already looking at the message, so a banner would
    /// only nag. The frontmost check also guards against a stale marker left
    /// by an app that quit or crashed with a thread open.
    private func isConversationOpenInForeground(_ conversationID: String) -> Bool {
        guard !conversationID.isEmpty,
              let open = appDefaults?.string(forKey: Self.openConversationKey),
              open == conversationID
        else { return false }
        return NSRunningApplication.runningApplications(withBundleIdentifier: appBundleID)
            .contains { $0.isActive && !$0.isHidden }
    }

    /// Brings Cylonix.app to the front, launching it if needed. openApplication
    /// (rather than NSRunningApplication.activate) also sends the reopen event
    /// that restores the window when the app was hidden to the tray.
    private func activateApp() {
        // The agent lives inside the app bundle
        // (Cylonix.app/Contents/Resources/CylonixNotifier.app).
        let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleID)
            ?? Bundle.main.bundleURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, err in
            if let err = err {
                NSLog("cylonix-notifier: failed to open app: \(err)")
            }
        }
    }

    // MARK: - Preferences shared with Cylonix.app

    // The app has no app group, so it keeps these in its standard defaults
    // domain (io.cylonix.sase.direct); this agent's bundle id is that domain
    // plus ".notifier".
    private static let notifierSuffix = ".notifier"
    // Settings > Notifications > "Show Notification Previews". Mirrors
    // PacketTunnelUserDefaultsKey.notificationPreviewEnabled; unset = on.
    private static let notificationPreviewKey = "NotificationPreviewEnabled"
    // Conversation currently shown by the app; written by MainFlutterWindow's
    // "setOpenConversation" handler, cleared when the thread closes.
    private static let openConversationKey = "OpenPeerConversationID"

    private let appBundleID: String = {
        let suffix = NotifierApp.notifierSuffix
        let own = Bundle.main.bundleIdentifier ?? "io.cylonix.sase.direct\(suffix)"
        return own.hasSuffix(suffix) ? String(own.dropLast(suffix.count)) : "io.cylonix.sase.direct"
    }()

    private var appDefaults: UserDefaults? { UserDefaults(suiteName: appBundleID) }

    private var notificationPreviewEnabled: Bool {
        guard let defaults = appDefaults else { return true }
        if defaults.object(forKey: Self.notificationPreviewKey) == nil { return true }
        return defaults.bool(forKey: Self.notificationPreviewKey)
    }

    private func postNotification(name: String, path: String, transferID: String) {
        let content = UNMutableNotificationContent()
        content.title = "File Received"
        if notificationPreviewEnabled {
            let displayName = name.isEmpty ? "a file" : name
            content.body = "Saved \(displayName) to Downloads/Cylonix"
        } else {
            content.body = "Saved to Downloads/Cylonix"
        }
        content.sound = .default
        if !path.isEmpty {
            content.userInfo = ["path": path]
        }
        let id = !transferID.isEmpty
            ? "cylonix-direct-\(transferID)"
            : "cylonix-direct-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                NSLog("cylonix-notifier: add notification failed: \(err)")
            }
        }
    }
}

let app = NSApplication.shared
let delegate = NotifierApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
