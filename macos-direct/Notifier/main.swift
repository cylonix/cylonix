// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause
//
// CylonixNotifier: a background LaunchAgent that surfaces direct-mode
// Taildrop "file received" events as macOS user notifications.
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
private let watchPath  = "/localapi/v0/watch-ipn-bus?mask=0"
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
        guard let path = response.notification.request.content.userInfo["path"] as? String,
              !path.isEmpty else { return }
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
            let n = read(fd, &chunkBuf, chunkBuf.count)
            if n <= 0 { return }
            carry.append(chunkBuf, count: n)
            if !headersConsumed {
                if let r = carry.range(of: Data([0x0d, 0x0a, 0x0d, 0x0a])) {
                    carry.removeSubrange(carry.startIndex..<r.upperBound)
                    headersConsumed = true
                } else {
                    continue
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
        }
    }

    private func handleLine(_ data: Data) {
        // Only attempt JSON parse on lines that look like JSON objects.
        guard data.first == 0x7B /* '{' */ else { return }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        guard let dfr = obj["CylonixDirectFileReceived"] as? [String: Any] else { return }
        let name = (dfr["name"] as? String) ?? ""
        let path = (dfr["path"] as? String) ?? ""
        let transferID = (dfr["transfer_id"] as? String) ?? ""
        DispatchQueue.main.async { [weak self] in
            self?.postNotification(name: name, path: path, transferID: transferID)
        }
    }

    private func postNotification(name: String, path: String, transferID: String) {
        let content = UNMutableNotificationContent()
        content.title = "File Received"
        let displayName = name.isEmpty ? "a file" : name
        content.body = "Saved \(displayName) to Downloads/Cylonix"
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
