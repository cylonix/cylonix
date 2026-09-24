// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import CFNetwork
import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

// MARK: – Distribution mode detection

private let isDirectMode: Bool = {
    if let mode = Bundle.main.object(forInfoDictionaryKey: "io.cylonix.distribution_mode") as? String {
        return mode == "direct"
    }
    // Share extensions: check parent app bundle
    if let appBundlePath = Bundle.main.bundlePath.components(separatedBy: ".app/").first {
        let appBundle = Bundle(path: appBundlePath + ".app")
        if let mode = appBundle?.object(forInfoDictionaryKey: "io.cylonix.distribution_mode") as? String {
            return mode == "direct"
        }
    }
    return false
}()

public func containerURL() -> URL? {
    #if os(macOS)
        #if DEBUG
            if let appGroupId = Bundle.main.object(forInfoDictionaryKey: "DebugAppGroupId") as? String,
               appGroupId != ""
            {
                debugLog("Using debug app group ID \(appGroupId)")
                return FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
            }
        #endif
    #endif

    guard let appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String)
    else {
        debugLog("Failed to get app group ID")
        return nil
    }
    return FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
}

func sharedTempFolder() -> URL? {
    if isDirectMode {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("io.cylonix.share", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: tmpDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return tmpDir
    }
    guard let base = containerURL() else { return nil }
    let shareDir = base.appendingPathComponent("share", isDirectory: true)
    let tmpDir = shareDir.appendingPathComponent("tmp", isDirectory: true)
    try? FileManager.default.createDirectory(
        at: tmpDir,
        withIntermediateDirectories: true,
        attributes: nil
    )
    return tmpDir
}

/// Folder the extension drops share-request manifests into when it hands a
/// share over to the main app (e.g. "send as peer message"). App-group
/// builds share it with the app; the direct build's sandboxed extension
/// writes into its own container tmp, which the unsandboxed app can read.
func shareRequestsFolder() -> URL? {
    let dir: URL
    if isDirectMode {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("io.cylonix.share", isDirectory: true)
            .appendingPathComponent("requests", isDirectory: true)
    } else {
        guard let base = containerURL() else { return nil }
        dir = base.appendingPathComponent("share", isDirectory: true)
            .appendingPathComponent("requests", isDirectory: true)
    }
    try? FileManager.default.createDirectory(
        at: dir,
        withIntermediateDirectories: true,
        attributes: nil
    )
    return dir
}

/// Writes the manifest the app reads to present the shared files. The temp
/// copies are marked ephemeral: the app owns and deletes them from here.
func writeShareRequest(files: [SharedFile], mode: String) -> URL? {
    guard let dir = shareRequestsFolder() else {
        debugLog("Failed to locate share requests folder")
        return nil
    }
    var manifest: [String: Any] = [
        "version": 1,
        "mode": mode,
        "source": "share-extension",
        "ephemeral": true,
        "created_at": ISO8601DateFormatter().string(from: Date()),
        "files": files.map {
            ["path": $0.path, "name": $0.name, "size": $0.size, "kind": $0.kind.rawValue]
        },
    ]
    // Shared text and links travel as text too, so a peer message can carry
    // them as its body rather than as a .txt/.webloc attachment.
    let texts = files.compactMap { $0.kind == .file ? nil : $0.text }
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    if !texts.isEmpty {
        manifest["text"] = texts.joined(separator: "\n\n")
    }
    do {
        let data = try JSONSerialization.data(withJSONObject: manifest, options: [])
        let url = dir.appendingPathComponent("\(UUID().uuidString).json")
        try data.write(to: url, options: .atomic)
        debugLog("Wrote share request \(url.path)")
        return url
    } catch {
        debugLog("Failed to write share request: \(error)")
        return nil
    }
}

// MARK: – Direct daemon HTTP client

#if os(macOS)
private class DirectDaemonClient {
    static let socketPath = "/var/run/cylonix/cylonixd.sock"

    func getStatus() async throws -> Status {
        let data = try await httpRequest(method: "GET", path: "/localapi/v0/status")
        return try JSONDecoder().decode(Status.self, from: data)
    }

    func sendFiles(peerID: String, files: [OutgoingFileData]) async throws -> String {
        let boundary = "CylonixBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        var body = Data()

        // First part: JSON manifest (required by the LocalAPI)
        let manifest = files.map { ["ID": $0.ID, "Name": $0.Name, "DeclaredSize": $0.DeclaredSize, "PeerID": $0.PeerID] } as [[String: Any]]
        let manifestData = try JSONSerialization.data(withJSONObject: manifest)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"manifest.json\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(manifestData)
        body.append("\r\n".data(using: .utf8)!)

        // Subsequent parts: actual file data
        for file in files {
            guard let path = file.Path,
                  let fileData = FileManager.default.contents(atPath: path) else { continue }
            let safeName = file.Name.replacingOccurrences(of: "\"", with: "_")
                .replacingOccurrences(of: ";", with: "_")
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let headers = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)",
            "Content-Length": "\(body.count)",
        ]
        let data = try await httpRequest(method: "POST", path: "/localapi/v0/file-put/\(peerID)",
                                         headers: headers, body: body, timeout: 300)
        return String(data: data, encoding: .utf8) ?? "Success"
    }

    /// One HTTP/1.1 exchange over the daemon's unix socket with plain POSIX
    /// sockets. NWConnection was used before, but it runs every connection,
    /// even to a local unix socket, through network path evaluation, which
    /// inside the extension intermittently answered "Network is down"
    /// (ENETDOWN) on the first attempt and left the device list empty until a
    /// manual refresh. A raw socket needs no path.
    private func httpRequest(method: String, path: String,
                             headers: [String: String] = [:],
                             body: Data? = nil,
                             timeout: TimeInterval = 30) async throws -> Data {
        var request = "\(method) \(path) HTTP/1.1\r\nHost: local-tailscaled.sock\r\nConnection: close\r\n"
        for (key, value) in headers {
            request += "\(key): \(value)\r\n"
        }
        if let body = body, headers["Content-Length"] == nil {
            request += "Content-Length: \(body.count)\r\n"
        }
        request += "\r\n"
        var requestData = Data(request.utf8)
        if let body = body {
            requestData.append(body)
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let response = try Self.exchange(requestData, socketPath: Self.socketPath, timeout: timeout)
                    continuation.resume(returning: self.body(of: response))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func posixError(_ operation: String) -> NSError {
        let code = Int(errno)
        return NSError(
            domain: NSPOSIXErrorDomain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: "\(operation): \(String(cString: strerror(Int32(code))))"]
        )
    }

    /// Connects, writes the whole request (multipart uploads can be large)
    /// and reads until the daemon closes the connection.
    private static func exchange(_ request: Data, socketPath: String, timeout: TimeInterval) throws -> Data {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw posixError("socket") }
        defer { close(fd) }

        var tv = timeval(tv_sec: Int(timeout), tv_usec: 0)
        _ = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        _ = setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        var noSigPipe: Int32 = 1
        _ = setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8)
        let capacity = MemoryLayout.size(ofValue: addr.sun_path)
        guard pathBytes.count < capacity else {
            throw NSError(domain: "DirectDaemonClient", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "socket path too long"])
        }
        withUnsafeMutableBytes(of: &addr.sun_path) { raw in
            let buf = raw.bindMemory(to: UInt8.self)
            for i in 0 ..< pathBytes.count { buf[i] = pathBytes[i] }
            buf[pathBytes.count] = 0
        }
        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        let rc = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sp in
                connect(fd, sp, size)
            }
        }
        guard rc == 0 else { throw posixError("connect") }

        try request.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            guard let base = raw.baseAddress else { return }
            var sent = 0
            while sent < raw.count {
                let n = send(fd, base.advanced(by: sent), raw.count - sent, 0)
                if n < 0 {
                    if errno == EINTR { continue }
                    throw posixError("send")
                }
                if n == 0 {
                    throw NSError(domain: "DirectDaemonClient", code: -3,
                                  userInfo: [NSLocalizedDescriptionKey: "connection closed while sending"])
                }
                sent += n
            }
        }

        var response = Data()
        var chunk = [UInt8](repeating: 0, count: 65536)
        while true {
            let n = chunk.withUnsafeMutableBytes { buf -> Int in
                recv(fd, buf.baseAddress, buf.count, 0)
            }
            if n < 0 {
                if errno == EINTR { continue }
                throw posixError("recv")
            }
            if n == 0 { break }
            response.append(contentsOf: chunk[0 ..< n])
        }
        return response
    }

    /// HTTP body after the header block, de-chunked when needed.
    private func body(of responseData: Data) -> Data {
        guard let range = responseData.range(of: Data("\r\n\r\n".utf8)) else {
            return responseData
        }
        let bodyData = responseData.subdata(in: range.upperBound ..< responseData.endIndex)
        let headerText = String(
            data: responseData.subdata(in: responseData.startIndex ..< range.lowerBound),
            encoding: .utf8
        ) ?? ""
        if headerText.lowercased().contains("transfer-encoding: chunked") {
            return decodeChunked(bodyData)
        }
        return bodyData
    }

    private func decodeChunked(_ data: Data) -> Data {
        var result = Data()
        var offset = 0
        let bytes = [UInt8](data)
        while offset < bytes.count {
            // Find end of chunk size line
            var lineEnd = offset
            while lineEnd < bytes.count - 1 {
                if bytes[lineEnd] == 0x0D && bytes[lineEnd + 1] == 0x0A { break }
                lineEnd += 1
            }
            guard lineEnd < bytes.count - 1 else { break }
            let sizeStr = String(bytes: bytes[offset..<lineEnd], encoding: .utf8)?.trimmingCharacters(in: .whitespaces) ?? "0"
            guard let chunkSize = UInt64(sizeStr, radix: 16), chunkSize > 0 else { break }
            let chunkStart = lineEnd + 2
            let chunkEnd = chunkStart + Int(chunkSize)
            guard chunkEnd <= bytes.count else { break }
            result.append(contentsOf: bytes[chunkStart..<chunkEnd])
            offset = chunkEnd + 2 // skip trailing \r\n
        }
        return result
    }
}

#endif

// MARK: – C callbacks

func fileDropDarwinCallback(
    _: CFNotificationCenter?,
    _ observerRaw: UnsafeMutableRawPointer?,
    _ cfName: CFNotificationName?,
    _: UnsafeRawPointer?,
    _: CFDictionary?
) {
    guard let observerRaw = observerRaw else { return }
    let me = Unmanaged<FileDropViewModel>
        .fromOpaque(observerRaw)
        .takeUnretainedValue()
    let name = cfName?.rawValue as String? ?? ""
    me.handleMessageNotification(name: name)
}

func fileDropDarwinNotificationCallback(
    _: CFNotificationCenter?,
    _ observerRaw: UnsafeMutableRawPointer?,
    _: CFNotificationName?,
    _: UnsafeRawPointer?,
    _: CFDictionary?
) {
    guard let observerRaw = observerRaw else { return }
    let me = Unmanaged<FileDropViewModel>
        .fromOpaque(observerRaw)
        .takeUnretainedValue()
    debugLog("FileDropDarwinNotificationCallback")
    me.handleProgressNotification()
}

#if os(macOS)
    private let bgColor = Color(NSColor.windowBackgroundColor)
#else
    private let bgColor = Color(UIColor.systemBackground)
#endif

private struct GlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            content
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect()
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

/// How the shared files are delivered. File drop is handled here in the
/// extension; a peer message needs the app's message store and outbound
/// queue, so that path hands the files over to the app.
enum ShareDeliveryMode: String, CaseIterable, Identifiable {
    case fileDrop = "File Drop"
    case peerMessage = "Peer Message"

    var id: String { rawValue }
}

public struct FileDropView: View {
    @StateObject private var viewModel = FileDropViewModel()
    let sharedFiles: [SharedFile]
    let unSupportedTypes: Set<String>
    let onCancel: () -> Void
    /// Opens a URL in the containing app; supplied by the hosting view
    /// controller because the mechanism differs per platform. Returns false
    /// when the app could not be asked to open, in which case the request
    /// stays on disk for the app's next launch.
    var openHostApp: (URL) -> Bool = { _ in false }
    @State private var deliveryMode: ShareDeliveryMode = .fileDrop
    @State private var handOffHint: String?
    @State private var handingOff = false
    @State private var searchText = ""
    @State private var showOnlineOnly = false
    #if os(iOS)
        // prevent auto-focus on the search field
        @FocusState private var searchFieldIsFocused: Bool
    #endif

    // The macOS sheet is a fixed 480pt wide, so the search field can claim
    // 200pt; on iOS it takes whatever the toggle and refresh control leave
    // over, otherwise the row overflows on phone widths.
    private var searchFieldMinWidth: CGFloat {
        #if os(macOS)
            return 200
        #else
            return 0
        #endif
    }

    private var filteredPeers: [PeerStatus] {
        var peers = viewModel.status?.userPeers ?? []
        if showOnlineOnly {
            peers = peers.filter { $0.online }
        }
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            peers = peers.filter {
                $0.dnsName.lowercased().contains(lower) ||
                    ($0.os?.lowercased().contains(lower) ?? false)
            }
        }
        return peers.sorted { lhs, rhs in
            let nameOrder = lhs.sortName.localizedStandardCompare(rhs.sortName)
            if nameOrder != .orderedSame {
                return nameOrder == .orderedAscending
            }
            return lhs.listID < rhs.listID
        }
    }

    public var body: some View {
        VStack {
            HStack {
                Image("ExtensionIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipped()
                    .cornerRadius(8)
                Text("Cylonix")
                    .font(.subheadline)
                Spacer()
                Text(deliveryMode == .peerMessage ? "Send as Message" : "Send Files")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    viewModel.cleanupSharedTemp(for: sharedFiles)
                    onCancel()
                }
                .modifier(GlassButtonModifier())
            }
            .padding()

            if sharedFiles.isEmpty {
                Spacer()
                Text("The selected file types are not supported for sharing.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                if !unSupportedTypes.isEmpty {
                    Text("Unsupported types:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    Text(Array(unSupportedTypes).joined(separator: ", "))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
                Spacer().frame(height: 0)
                Spacer()
            } else {
                FileHeaderView(files: sharedFiles)
                if !unSupportedTypes.isEmpty {
                    Text("Unsupported types: \(Array(unSupportedTypes).joined(separator: ", "))")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                Divider()

                deliveryModePicker

                if deliveryMode == .peerMessage {
                    peerMessagePanel
                } else {
                    fileDropSection
                }
            }
        }
        #if os(macOS)
        .frame(width: 480, height: 800)
        #endif
        .padding()
        .background {
            if #available(iOS 26, macOS 26, *) {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                Rectangle().fill(bgColor)
            }
        }
        .onAppear {
            viewModel.loadStatus()
            #if os(iOS)
                // make sure the keyboard is not up
                searchFieldIsFocused = false
            #endif
        }
    }

    // The picker and its hint are centred independently of each other: in
    // a leading-aligned stack the longer Peer Message hint widened the
    // stack and slid the picker to the left on every switch.
    private var deliveryModePicker: some View {
        VStack(alignment: .center, spacing: 4) {
            Picker("Delivery", selection: $deliveryMode) {
                ForEach(ShareDeliveryMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            Text(deliveryMode == .peerMessage
                ? "Text and links become the message; files are attached. Queued if the peer is offline."
                : "Sent straight to a device that is online now.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var fileDropSection: some View {
        HStack {
            TextField("Search name or OS…", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minWidth: searchFieldMinWidth)
            #if os(iOS)
                .focused($searchFieldIsFocused)
            #endif

            Toggle("Online Only", isOn: $showOnlineOnly)
                // Hug content so the label isn't squeezed into
                // per-character wrapping on narrow phone layouts.
                .fixedSize()
            #if os(macOS)
                .toggleStyle(CheckboxToggleStyle())
            #endif

            if viewModel.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 24, height: 24)
            } else {
                Button {
                    viewModel.loadStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
                .help("Refresh device status")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.clear)

        if viewModel.isLoading {
            Spacer()
            ProgressView("Loading devices...")
            Spacer()
        } else if filteredPeers.isEmpty {
            Spacer()
            Text("No device available to share with")
                .foregroundColor(.secondary)
            Spacer()
        } else {
            List(filteredPeers, id: \.listID) { peer in
                PeerRow(
                    peer: peer,
                    transfer: viewModel.transfers[peer.transferID],
                    onSend: { viewModel.sendFiles(to: peer, files: sharedFiles) },
                    onRetry: { viewModel.retryFailedFiles(for: peer) }
                )
            }.navigationTitle("Devices")
                .listStyle(.plain)
                .modifier(HideScrollBackground())
                .background(Color.clear)
            #if os(iOS)
                .refreshable { await viewModel.refreshStatus() }
            #endif
        }
    }

    /// The peer-message path: the thread list and composer live in the app,
    /// so this panel hands the files over and opens Cylonix.
    private var peerMessagePanel: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
            Text("Send as a peer message")
                .font(.headline)
            Text(peerMessageDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                handOffToApp()
            } label: {
                Label("Continue in Cylonix", systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(.borderedProminent)
            .disabled(handingOff)
            if let hint = handOffHint {
                Text(hint)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var peerMessageDescription: String {
        let textItems = sharedFiles.filter { $0.kind != .file }.count
        let fileItems = sharedFiles.count - textItems
        let intro = "Cylonix opens so you can pick a conversation or start a new one. "
        if fileItems == 0 {
            return intro + "The shared text is sent as the message itself, not as a file, and reaches the peer even if it is offline right now."
        }
        if textItems > 0 {
            return intro + "The text becomes the message and the files go out as attachments; they reach the peer even if it is offline right now."
        }
        return intro + "The files go out as attachments and reach the peer even if it is offline right now."
    }

    private func handOffToApp() {
        guard let manifestURL = writeShareRequest(files: sharedFiles, mode: "peer-message") else {
            handOffHint = "Could not prepare the shared files for Cylonix."
            return
        }
        var components = URLComponents()
        components.scheme = "cylonix"
        components.host = "share"
        components.queryItems = [
            URLQueryItem(name: "mode", value: "peer-message"),
            URLQueryItem(name: "manifest", value: manifestURL.path),
        ]
        guard let url = components.url else {
            handOffHint = "Could not build the Cylonix link."
            return
        }
        handingOff = true
        let opened = openHostApp(url)
        debugLog("Hand-off to app: opened=\(opened) url=\(url)")
        // iOS has no supported way for an extension to open its app; the
        // responder-chain call usually works but is not guaranteed, and the
        // request waits on disk either way.
        #if os(iOS)
            handOffHint = opened
                ? "Opening Cylonix… If it does not open, open Cylonix to finish sending."
                : "Open Cylonix to finish sending — the files are waiting there."
        #else
            handOffHint = opened
                ? "Opening Cylonix…"
                : "Open Cylonix to finish sending — the files are waiting there."
        #endif
        // Leave the sheet up long enough for the open to be dispatched (and,
        // when it could not be, for the hint to be read). The app owns the
        // temp files from here, so no cleanup.
        DispatchQueue.main.asyncAfter(deadline: .now() + (opened ? 0.8 : 2.5)) {
            onCancel()
        }
    }
}

private struct HideScrollBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
            if #available(iOS 16.0, *) {
                content.scrollContentBackground(.hidden)
            } else {
                content
            }
        #else
            content
        #endif
    }
}

class FileDropViewModel: ObservableObject {
    @Published private(set) var status: Status?
    @Published private(set) var transfers: [String: PeerTransferState] = [:]
    @Published private(set) var isLoading = true
    @Published private(set) var isRefreshing = false

    private var pending = [String: (Data?) -> Void]()
    private let channelSuffix = "share"
    private var channel: String { PacketTunnelMessage.prefix + channelSuffix }
    #if os(macOS)
    private let daemonClient: DirectDaemonClient? = isDirectMode ? DirectDaemonClient() : nil
    #endif

    init() {
        debugLog("FileDropViewModel init (direct=\(isDirectMode))")
        if !isDirectMode {
            setupResponseListener()
            setupProgressListener()
        }
        debugLog("FileDropViewModel init done")
    }

    deinit {
        if !isDirectMode {
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            CFNotificationCenterRemoveObserver(
                center,
                Unmanaged.passUnretained(self).toOpaque(),
                nil,
                nil
            )
        }
        debugLog("FileDropViewModel deinit")
    }

    private func setupResponseListener() {
        let responseNote = (channel + ".response") as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()

        debugLog("ENTER setupResponseListener()")

        // in case someone re‐calls setup, nuke any old observer first
        CFNotificationCenterRemoveObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil
        )

        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            fileDropDarwinCallback, // free function, no captures
            responseNote, // name to observe
            nil,
            .deliverImmediately
        )

        debugLog("CFNotification observer installed for \(responseNote)")
    }

    /// Called from the C callback
    fileprivate func handleMessageNotification(name: String) {
        debugLog("⚡️ handleMessageNotification(\(name))")

        guard name == channel + ".response" else {
            debugLog("— skipping unexpected notification \(name)")
            return
        }

        guard let groupURL = containerURL() else {
            debugLog("Failed to get containerURL()")
            return
        }
        let respURL = groupURL.appendingPathComponent(
            PacketTunnelMessage.responseFile(channel: channel)
        )

        guard let data = try? Data(contentsOf: respURL) else {
            debugLog("– response read failed at \(respURL.path)")
            return
        }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let id = json["id"] as? String,
            let cb = pending[id]
        else {
            debugLog("– malformed JSON: \(String(decoding: data, as: UTF8.self))")
            return
        }

        debugLog("Invoking pending[\(id)] \(String(describing: json["payload"]))")
        let payloadValue = json["payload"]
        let payloadData: Data?
        if let s = payloadValue as? String {
            payloadData = Data(s.utf8)
        } else if let d = payloadValue as? Data {
            payloadData = d
        } else {
            payloadData = nil
        }
        debugLog("Invoking pending[\(id)] with \(String(describing: payloadData))")
        cb(payloadData)
        pending.removeValue(forKey: id)
    }

    private func setupProgressListener() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let note = TunnelNotification.channel as CFString

        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            fileDropDarwinNotificationCallback,
            note,
            nil,
            .deliverImmediately
        )
        debugLog("Installed progress observer for \(note)")
    }

    fileprivate func handleProgressNotification() {
        guard
            let groupURL = containerURL(),
            let data = try? Data(contentsOf: groupURL.appendingPathComponent(TunnelNotification.queueFile))
        else {
            debugLog("Failed to read progress notification")
            return
        }
        let outgoingFiles: [OutgoingFileData]
        do {
            let wrappers = try JSONDecoder().decode([NotificationWrapper].self, from: data)
            guard let last = wrappers.last?.record else {
                debugLog("No progress notification found")
                return
            }
            outgoingFiles = last.OutgoingFiles ?? []
        } catch {
            debugLog("Failed to decode progress notification: \(error)")
            return
        }
        if outgoingFiles.isEmpty {
            // debugLog("No outgoing files in progress notification")
            return
        }

        debugLog("progress: processing \(outgoingFiles.count) outgoing files")

        // group the file‐records by peerID
        let byPeer = Dictionary(grouping: outgoingFiles, by: { $0.PeerID })

        for (peerID, records) in byPeer {
            guard var ts = transfers[peerID] else { continue }

            // 1) Update the ts.files entries with the new Sent/Finished/Succeeded
            var updatedFiles = ts.files
            for rec in records {
                if let idx = updatedFiles.firstIndex(where: { $0.ID == rec.ID }) {
                    updatedFiles[idx].Sent = rec.Sent
                    updatedFiles[idx].Finished = rec.Finished
                    updatedFiles[idx].Succeeded = rec.Succeeded
                }
            }
            ts.files = updatedFiles

            // 2) Re‐tally totalSent over all ts.files (including previous successes)
            let totalSent = ts.files.reduce(Int64(0)) { $0 + $1.Sent }
            let totalSize = ts.files.reduce(Int64(0)) { $0 + $1.DeclaredSize }
            let progress = totalSize > 0
                ? Double(totalSent) / Double(totalSize)
                : ts.progress

            // 3) Determine overall status
            let allFinished = ts.files.allSatisfy { $0.Finished }
            let allSucceeded = ts.files.allSatisfy { $0.Succeeded }
            let status: TransferStatus = {
                if !allFinished { return .sending }
                else if allFinished && !allSucceeded { return .failed }
                else { return .complete }
            }()
            DispatchQueue.main.async {
                debugLog("peer \(peerID) → progress \(progress) status \(status)")
                if ts.status == .failed || ts.status == .complete {
                    debugLog("peer \(peerID) is \(ts.status), ignoring new status \(status) that may arrive later")
                } else {
                    ts.status = status
                }
                ts.progress = progress
                self.transfers[peerID] = ts
            }
        }
    }

    private func postMessage(_ payload: [String: Any],
                             response: @escaping (Data?) -> Void)
    {
        var msg = payload
        let id = UUID().uuidString
        msg["id"] = id

        guard let groupURL = containerURL() else {
            debugLog("postMessage: Failed to get container URL")
            return
        }
        let msgURL = groupURL.appendingPathComponent(
            PacketTunnelMessage.messageFile(channel: channel))

        guard let data = try? JSONSerialization.data(withJSONObject: msg) else {
            debugLog("– cannot serialize message: \(msg)")
            return
        }
        do {
            try data.write(to: msgURL, options: .atomic)
            debugLog("Wrote message \(id) → \(msgURL.lastPathComponent)")
        } catch {
            debugLog("– write error: \(error)")
            return
        }

        pending[id] = response
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(channel as CFString),
            nil, nil, true
        )
        debugLog("Posted notification \(channel)")
    }

    func loadStatus() {
        // Full-screen loading only before the first status arrives; later
        // calls refresh in place so the peer list stays visible.
        if status == nil {
            isLoading = true
        }
        isRefreshing = true
        debugLog("loadStatus()")

        #if os(macOS)
        if let client = daemonClient {
            Task {
                // A daemon restart or a transient socket error should not
                // leave an empty list behind a refresh button.
                var attempt = 0
                while true {
                    do {
                        let s = try await client.getStatus()
                        await MainActor.run {
                            self.status = s
                            self.finishLoading()
                        }
                        return
                    } catch {
                        attempt += 1
                        debugLog("Direct loadStatus failed (attempt \(attempt)): \(error)")
                        if attempt >= 3 {
                            await MainActor.run { self.finishLoading() }
                            return
                        }
                        try? await Task.sleep(nanoseconds: 700_000_000)
                    }
                }
            }
            return
        }
        #endif

        postMessage(["method": "status"]) { [weak self] data in
            debugLog("loadStatus response: \(String(describing: data))")
            DispatchQueue.main.async {
                if let data = data,
                   let status = try? JSONDecoder().decode(Status.self, from: data)
                {
                    self?.status = status
                }
                self?.finishLoading()
            }
        }
    }

    private func finishLoading() {
        isLoading = false
        isRefreshing = false
    }

    /// Async wrapper for pull-to-refresh. The tunnel may never answer the
    /// status message (pending IPC callbacks have no timeout), so give up
    /// after 10s rather than leaving the spinner up forever.
    @MainActor
    func refreshStatus() async {
        loadStatus()
        for _ in 0 ..< 50 {
            guard isRefreshing else { return }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        finishLoading()
    }

    /// Retry only the failed files for this peer.
    func retryFailedFiles(for peer: PeerStatus) {
        guard let ts = transfers[peer.id],
              ts.status == .failed
        else { return }
        // Just re-send; sendFiles will detect existing state and only resend failures
        debugLog("Retrying failed files for peer \(peer.id)")
        sendFiles(to: peer, files: nil)
    }

    func sendFiles(to peer: PeerStatus, files: [SharedFile]?) {
        debugLog("sendFiles(to:\(peer.id))")

        let toSend: [OutgoingFileData]
        var newState: PeerTransferState

        if let ts = transfers[peer.id], files == nil {
            // retry case: keep successes, reset failures
            let failed = ts.files.filter { $0.Finished && !$0.Succeeded }
            // reset each failed item in the state
            let resetFailedIDs = Set(failed.map { $0.ID })
            let updatedFiles = ts.files.map { f in
                var f2 = f
                if resetFailedIDs.contains(f.ID) {
                    f2.Sent = 0
                    f2.Finished = false
                    f2.Succeeded = false
                }
                return f2
            }
            // compute existing progress from kept successes
            let totalSent = updatedFiles.reduce(Int64(0)) { $0 + $1.Sent }
            let totalSize = updatedFiles.reduce(Int64(0)) { $0 + $1.DeclaredSize }
            let initialProg = totalSize > 0 ? Double(totalSent) / Double(totalSize) : 0

            newState = PeerTransferState(
                peerID: peer.id,
                files: updatedFiles,
                progress: initialProg,
                status: .sending,
                errorMessage: nil
            )
            toSend = failed
            debugLog("Retrying \(failed.count) files")
        } else {
            let outgoing = (files ?? []).map { file -> OutgoingFileData in
                let id = UUID().uuidString
                return OutgoingFileData(
                    ID: id,
                    PeerID: peer.id,
                    Name: file.name,
                    Path: file.path,
                    Sent: 0,
                    Finished: false,
                    Succeeded: false,
                    DeclaredSize: file.size
                )
            }
            newState = PeerTransferState(
                peerID: peer.id,
                files: outgoing,
                progress: 0,
                status: .sending,
                errorMessage: nil
            )
            toSend = outgoing
            debugLog("Sending \(outgoing.count) files")
        }
        // commit new state
        DispatchQueue.main.async {
            self.transfers[peer.id] = newState
        }

        // Ignore if there is no file to send
        if toSend.isEmpty {
            DispatchQueue.main.async {
                if var ts = self.transfers[peer.id] {
                    ts.status = .failed
                    ts.errorMessage = "No file to send"
                    self.transfers[peer.id] = ts
                    debugLog("Send failed: \(ts.errorMessage)")
                }
            }
            return
        }

        #if os(macOS)
        if let client = daemonClient {
            Task {
                do {
                    let result = try await client.sendFiles(peerID: peer.id, files: toSend)
                    debugLog("Direct sendFiles result: \(result)")
                    await MainActor.run {
                        if var ts = self.transfers[peer.id] {
                            ts.status = .complete
                            ts.progress = 1.0
                            self.transfers[peer.id] = ts
                        }
                    }
                } catch {
                    debugLog("Direct sendFiles failed: \(error)")
                    await MainActor.run {
                        if var ts = self.transfers[peer.id] {
                            ts.status = .failed
                            ts.errorMessage = error.localizedDescription
                            self.transfers[peer.id] = ts
                        }
                    }
                }
            }
            return
        }
        #endif

        let args = SendFilesArguments(peerID: peer.id, files: toSend)
        guard let argData = try? JSONEncoder().encode(args),
              let argJSON = String(data: argData, encoding: .utf8)
        else {
            debugLog("Failed to encode sendFiles arguments")
            return
        }
        let payload: [String: String] = [
            "method": "send_files_to_peer",
            "arguments": argJSON,
        ]

        postMessage(payload) { [weak self] data in
            let resp = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no-response>"
            debugLog("sendFiles result: \(resp)")
            DispatchQueue.main.async {
                guard let self = self else { return }
                if var ts = self.transfers[peer.id] {
                    if resp.hasPrefix("Success") {
                        ts.status = .complete
                        ts.progress = 1.0
                    } else {
                        ts.status = .failed
                        ts.errorMessage = resp
                        debugLog("Send failed: \(ts.errorMessage)")
                    }
                    self.transfers[peer.id] = ts
                }
            }
        }
    }
}

extension FileDropViewModel {
    /// Remove only those temp files which have succeeded or failed on all peers.
    func cleanupSharedTemp(for sharedFiles: [SharedFile]) {
        let fm = FileManager.default
        for file in sharedFiles {
            // Find all transfer records matching this temp path
            let records = transfers.values
                .flatMap { $0.files }
                .filter { $0.Path == file.path }

            // Only delete if we have at least one record and all finished
            if !records.isEmpty, records.allSatisfy({ $0.Finished }) {
                try? fm.removeItem(at: URL(fileURLWithPath: file.path))
            }
        }
    }
}

private struct SendFilesArguments: Codable {
    enum CodingKeys: String, CodingKey {
        case peerID = "peer_id"
        case files
    }

    let peerID: String
    let files: [OutgoingFileData]
}

struct FileHeaderView: View {
    let files: [SharedFile]
    private let imageThumbnailSize: CGFloat = 48
    private let documentThumbnailSize: CGFloat = 32

    var body: some View {
        HStack {
            // Thumbnail for single image file, else generic icon
            if files.count == 1,
               let img = platformThumbnail(for: files[0].path)
            {
                img.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageThumbnailSize, height: imageThumbnailSize)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: files.count == 1 ? "doc" : "doc.on.doc")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: documentThumbnailSize, height: documentThumbnailSize)
            }

            VStack(alignment: .leading) {
                Text(files.count == 1 ? files[0].name : "\(files.count) files")
                    .font(files.count == 1 ? .subheadline : .headline)
                    .fontWeight(.bold)
                Text(ByteCountFormatter
                    .string(fromByteCount: files.reduce(0) { $0 + $1.size },
                            countStyle: .file))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func platformThumbnail(for path: String) -> Image? {
        let url = URL(fileURLWithPath: path)
        #if os(macOS)
            guard let ns = NSImage(contentsOf: url) else { return nil }
            return Image(nsImage: ns)
        #else
            guard let ui = UIImage(contentsOfFile: path) else { return nil }
            return Image(uiImage: ui)
        #endif
    }
}

private func osIconName(for os: String?) -> String {
    guard let os = os?.lowercased() else { return "questionmark.circle" }
    if os.contains("mac") { return "desktopcomputer" }
    if os.contains("win") { return "laptopcomputer" }
    if os.contains("linux") { return "terminal" }
    if os.contains("ios") { return "iphone" }
    if os.contains("android") { return "antenna.radiowaves.left.and.right" }
    return "questionmark.circle"
}

struct PeerRow: View {
    let peer: PeerStatus
    let transfer: PeerTransferState?
    let onSend: () -> Void
    let onRetry: () -> Void
    @State private var showDialog = false
    @State private var errorMessage: String?
    #if os(macOS)
    @State private var isHovered = false
    #endif
    private var displayName: String {
        peer.dnsName.components(separatedBy: ".").first ?? peer.dnsName
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(peer.online ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(peer.online ? .bold : .regular)
                HStack(spacing: 4) {
                    Image(systemName: osIconName(for: peer.os))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let os = peer.os {
                        Text(os)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let ts = transfer {
                switch ts.status {
                case .sending:
                    // combined progress bar
                    VStack(spacing: 2) {
                        ProgressView(value: ts.progress)
                            .frame(width: 100)
                        Text("\(Int(ts.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                case .failed:
                    HStack(spacing: 8) {
                        if let ts = transfer, !ts.allSuccessButWithFailedStatus {
                            Button("Retry") {
                                onRetry()
                            }
                            #if os(iOS)
                            // https://www.hackingwithswift.com/quick-start/swiftui/how-to-disable-the-overlay-color-for-images-inside-button-and-navigationlink
                            // Don't allow the row to be tappable
                            // Putting the button in a HStack
                            // didn't prevent the row from being tappable
                            .buttonStyle(.plain)
                            #endif
                            .foregroundColor(.accentColor)
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)

                            if let e = ts.errorMessage {
                                Button("View") {
                                    errorMessage = e
                                    showDialog = true
                                }
                                #if os(iOS)
                                // Don't allow the row to be tappable
                                // Putting the button in a HStack
                                // didn't prevent the row from being tappable
                                .buttonStyle(.plain)
                                #endif
                                .foregroundColor(.accentColor)
                                #if os(macOS)
                                .dialogIcon(Image(systemName: "exclamationmark.triangle"))
                                #endif
                            }
                        }
                        .alert("Transfer Error",
                               isPresented: $showDialog,
                               actions: {
                                   Button("OK", role: .cancel) {}
                               },
                               message: {
                                   Text(errorMessage ?? "Unknown error")
                               })

                    }.layoutPriority(1)
                case .complete:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else if peer.canReceiveFiles {
                #if os(macOS)
                if isHovered {
                    Button("Send", action: onSend)
                        .foregroundColor(.accentColor)
                }
                #else
                // On iOS, the whole row is tappable.
                Button("Send", action: onSend)
                    .foregroundColor(.accentColor)
                #endif
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
        .listRowBackground(Color.clear)
    }
}

/// What a shared item originally was. Text and links are written to disk as
/// .txt / .webloc so File Drop can push them; the peer-message path sends
/// their content as the message body instead and drops the synthetic file.
enum SharedFileKind: String, Codable {
    case file
    case text
    case url
}

struct SharedFile: Codable {
    let path: String
    let name: String
    let size: Int64
    let kind: SharedFileKind
    /// The original text or link for `.text` / `.url` items.
    let text: String?

    init(path: String, name: String, size: Int64, kind: SharedFileKind = .file, text: String? = nil) {
        self.path = path
        self.name = name
        self.size = size
        self.kind = kind
        self.text = text
    }
}

enum TransferStatus: String {
    case sending
    case complete
    case failed
}

struct PeerTransferState {
    let peerID: String
    var files: [OutgoingFileData]
    var progress: Double // 0.0…1.0
    var status: TransferStatus
    var errorMessage: String?

    // This could happen if the file is successfully sent but failed to be
    // processed by the receiving peer. e.g. filename is malformed.
    var allSuccessButWithFailedStatus: Bool {
        files.allSatisfy { $0.Finished && $0.Succeeded } && status == .failed
    }
}

struct Status: Codable {
    let backendState: String
    let selfStatus: PeerStatus
    let peer: [String: PeerStatus]

    enum CodingKeys: String, CodingKey {
        case backendState = "BackendState"
        case selfStatus = "Self"
        case peer = "Peer"
    }
}

struct PeerStatus: Identifiable, Codable {
    private static let unavailableStableID = "00000000-0000-0000-0000-000000000000"
    private static let taildropTargetAvailable = 1

    let id: String
    let publicKey: String
    let userID: Int
    let hostName: String
    let dnsName: String
    let online: Bool
    let os: String?
    let peerAPIURL: [String]?
    let taildropTarget: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case publicKey = "PublicKey"
        case hostName = "HostName"
        case dnsName = "DNSName"
        case online = "Online"
        case os = "OS"
        case peerAPIURL = "PeerAPIURL"
        case taildropTarget = "TaildropTarget"
        case userID = "UserID"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        publicKey = try container.decodeIfPresent(String.self, forKey: .publicKey) ?? ""
        userID = try container.decodeIfPresent(Int.self, forKey: .userID) ?? 0
        hostName = try container.decodeIfPresent(String.self, forKey: .hostName) ?? ""
        dnsName = try container.decodeIfPresent(String.self, forKey: .dnsName) ?? hostName
        online = try container.decodeIfPresent(Bool.self, forKey: .online) ?? false
        os = try container.decodeIfPresent(String.self, forKey: .os)
        peerAPIURL = try container.decodeIfPresent([String].self, forKey: .peerAPIURL)
        taildropTarget = try container.decodeIfPresent(Int.self, forKey: .taildropTarget) ?? 0
    }

    var listID: String {
        if !publicKey.isEmpty { return publicKey }
        if !id.isEmpty { return id }
        return dnsName
    }

    var transferID: String {
        id
    }

    var canReceiveFiles: Bool {
        online &&
            taildropTarget == Self.taildropTargetAvailable &&
            !id.isEmpty &&
            id != Self.unavailableStableID &&
            !(peerAPIURL?.isEmpty ?? true)
    }

    var sortName: String {
        dnsName.components(separatedBy: ".").first ?? dnsName
    }
}

extension Status {
    /// Returns only the peers belonging to the same user as `selfStatus`.
    var userPeers: [PeerStatus] {
        peer.values.filter { $0.userID == selfStatus.userID }
    }
}

// MARK: – Models for notifications

struct OutgoingFileData: Codable {
    let ID: String
    let PeerID: String
    let Name: String
    let Path: String?
    var Sent: Int64
    var Finished: Bool
    var Succeeded: Bool
    let DeclaredSize: Int64
}

private struct NotificationRecord: Codable {
    let OutgoingFiles: [OutgoingFileData]?
}

private struct NotificationWrapper: Decodable {
    let notificationJSON: String
    var record: NotificationRecord? {
        guard let data = notificationJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NotificationRecord.self, from: data)
    }

    enum CodingKeys: String, CodingKey {
        case notificationJSON = "notification"
    }
}

private enum TunnelNotification {
    static let channel = PacketTunnelNotification.ipnNotify
    static let queueFile = "notification_queue.json"
}
