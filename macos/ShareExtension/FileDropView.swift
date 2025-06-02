import CFNetwork
import Foundation
import SwiftUI

public func containerURL() -> URL? {
    guard let appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String)
    else {
        debugLog("Failed to get app group ID")
        return nil
    }
    return FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
}

func sharedTempFolder() -> URL? {
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

public struct FileDropView: View {
    @StateObject private var viewModel = FileDropViewModel()
    let sharedFiles: [SharedFile]
    let onCancel: () -> Void
    @State private var searchText = ""
    @State private var showOnlineOnly = false

    // derive a filtered peer list
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
        return peers
    }

    public var body: some View {
        VStack {
            // Header
            HStack {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Send Files")
                    .font(.headline)
                Spacer()
                 Button("Done") {
                    viewModel.cleanupSharedTemp(for: sharedFiles)
                    onCancel()
                }
            }.padding()

            // File header
            FileHeaderView(files: sharedFiles)

            Divider()

            // Search + Online-Only toggle
            HStack {
                TextField("Search name or OS…", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 200)
                Toggle("Online Only", isOn: $showOnlineOnly)
                    .toggleStyle(CheckboxToggleStyle())
            }
            .padding(.horizontal)


            if viewModel.isLoading {
                ProgressView("Loading devices...")
            } else if filteredPeers.isEmpty {
                Text("No devices to share with")
                    .foregroundColor(.secondary)
            } else {
                List(filteredPeers) { peer in
                    PeerRow(
                        peer: peer,
                        transfer: viewModel.transfers[peer.id],
                        onSend: { viewModel.sendFiles(to: peer, files: sharedFiles) },
                        onRetry: { viewModel.retryFailedFiles(for: peer) }
                    )
                }.navigationTitle("Devices")
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(width: 480, height: 600)
        .background(Color(.windowBackgroundColor))
        .onAppear { viewModel.loadStatus() }
    }
}

class FileDropViewModel: ObservableObject {
    @Published private(set) var status: Status?
    @Published private(set) var transfers: [String: PeerTransferState] = [:]
    @Published private(set) var isLoading = true

    private var pending = [String: (Data?) -> Void]()
    private let channelSuffix = "share"
    private var channel: String { PacketTunnelMessage.prefix + channelSuffix }

    init() {
        debugLog("FileDropViewModel init")
        setupResponseListener()
        setupProgressListener()
        debugLog("FileDropViewModel init done")
    }

    deinit {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        // remove *all* notifications for this observer
        CFNotificationCenterRemoveObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil
        )
        debugLog("FileDropViewModel deinit – removed Darwin observer")
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
                ts.progress = progress
                ts.status = status
                self.transfers[peerID] = ts
            }
            debugLog("peer \(peerID) → progress \(progress) status \(status)")
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
        isLoading = true
        debugLog("loadStatus()")
        postMessage(["method": "status"]) { [weak self] data in
            debugLog("loadStatus response: \(String(describing: data))")
            guard
                let data = data,
                let status = try? JSONDecoder().decode(Status.self, from: data)
            else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }
            DispatchQueue.main.async {
                self?.status = status
                self?.isLoading = false
            }
        }
    }

    /// Retry only the failed files for this peer.
    func retryFailedFiles(for peer: PeerStatus) {
        guard let ts = transfers[peer.id],
              ts.status == .failed
        else { return }
        // Just re-send; sendFiles will detect existing state and only resend failures
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
        }
        // commit new state
        DispatchQueue.main.async {
            self.transfers[peer.id] = newState
        }

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
            if !records.isEmpty && records.allSatisfy({ $0.Finished }) {
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
    private let thumbnailSize: CGFloat = 48

    var body: some View {
        HStack {
            // Thumbnail for single image file, else generic icon
            if files.count == 1,
               let thumb = imageThumbnail(for: files[0].path)
            {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: files.count == 1 ? "doc" : "doc.on.doc")
                    .resizable()
                    .frame(width: thumbnailSize, height: thumbnailSize)
            }

            VStack(alignment: .leading) {
                Text(files.count == 1 ? files[0].name : "\(files.count) files")
                    .font(.headline)
                Text(ByteCountFormatter
                    .string(fromByteCount: files.reduce(0) { $0 + $1.size },
                            countStyle: .file))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func imageThumbnail(for path: String) -> NSImage? {
        let url = URL(fileURLWithPath: path)
        guard let img = NSImage(contentsOf: url) else { return nil }
        // Optionally we could draw into an NSBitmapImageRep to size,
        // but simple resizable & aspectFit in SwiftUI works.
        return img
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
    @State private var showErrorAlert = false
    private var displayName: String {
        peer.dnsName.components(separatedBy: ".").first ?? peer.dnsName
    }

    var body: some View {
        HStack(spacing: 12) {
            // status dot
            Circle()
                .fill(peer.online ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            // title + subtitle
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
                    // show combined progress bar
                    VStack(spacing: 2) {
                        ProgressView(value: ts.progress)
                            .frame(width: 100)
                        Text("\(Int(ts.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                case .failed:
                    // show failure + retry
                    HStack(spacing: 8) {
                        Button("Retry") {
                            onSend()
                        }
                        .foregroundColor(.red)
                        if let _: String = ts.errorMessage {
                            Button("View Error") {
                                showErrorAlert = true
                            }
                        }
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    }
                case .complete:
                    // green checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else if peer.online {
                Button("Send", action: onSend)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .listRowBackground(Color(NSColor.windowBackgroundColor))
        .alert("Transfer Error",
               isPresented: $showErrorAlert,
               actions: {
                   Button("OK", role: .cancel) {}
               },
               message: {
                   Text(transfer?.errorMessage ?? "Unknown error")
               })
    }
}

struct SharedFile: Codable {
    let path: String
    let name: String
    let size: Int64
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
    let id: String
    let userID: Int
    let hostName: String
    let dnsName: String
    let online: Bool
    let os: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case hostName = "HostName"
        case dnsName = "DNSName"
        case online = "Online"
        case os = "OS"
        case userID = "UserID"
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
